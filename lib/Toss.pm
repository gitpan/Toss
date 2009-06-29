package Toss;

use warnings;
use strict;

=head1 NAME

Toss - Error or Warning management without eval

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.0.1';

use Devel::StackTrace;
use overload ('""'    => \&_stringify);

=head1 SYNOPSIS

Toss is for people who hate littering their code with eval blocks to capture errors. The idea is that your code becomes easier to read without them. 

NOTE: This concept goes against the typical design of how to manage failures inside perl. This module is here t
Quick summary of what the module does.

WARNING: This code is experimental and the interface may change between versions without warning. Comments are welcome at http://github.com/toddr/perl-Toss

Examples:

    package User;
    use Toss;

    sub get_user_info {
        $toss = 'Other Message";
        my $user_id = shift
            or return toss("Need a user ID to get you any information!");
       ...
    }
    
    package main;
    use User;
    
    my $id = '';
    my $user = User->get_user_info($id);
    if(!$user) {
        print "No user: $toss";    # 'No user: Need a user ID to get you any information!'
        print $toss->stack;        # Returns The stack trace from the first time the stack was called.
        print $toss->developer(1); # Returns developer message from the second time toss was called.
        print $toss->time_stamp;   # Returns DateTime object from when the toss event happened
    }
    
    

=head1 EXPORT

toss is exported by default. Everything else is an object sub called by the generated object.

=cut

require Exporter;
our @ISA = qw(Exporter);
our $toss = '';
our @EXPORT = qw(
    toss
    tossdie
    $toss
);

=head1 FUNCTIONS

=head2 toss

Not a object function. Syntactic sugar that allows you to return undef, while setting an error and possibly a developer message at the same time.

    my $user = shift or return toss("Cannot login without a valid user name");
    my $pass = shift or return toss("password cannot be blank", "Developer level message here");

    or if the sub your calling sets $toss...
    
    $toss = "Some ugly message from a module we user but don't want the user to see";
    my $dbh = $owned_module->get_something() or return toss ("The module didn't like me") # $toss automatically becomes the developer message
    
    DON'T DO this:
    $toss = "Some ugly message from a module we user but don't want the user to see";
    my $dbh = $owned_module->get_something() or return toss ("The module didn't like me", $toss) # $toss will be in the developer message twice if you do this.
    
=cut

sub toss { # This is essentially a new function, except it's not called in the format of Toss->toss
    my $user_message = shift;
    my $programmer_message = shift;
    
    # Stringify the toss message if an object was thrown.
    $user_message = "$user_message" if(ref($user_message) ne '');
    (ref($user_message) eq '') or die; # It's not clear under what circumstances this could happen?

    # Stringify $toss if it's already populated with something other than toss
    $toss = "$toss" if(defined $toss && ref($toss) ne "Toss");

    # make sure there's a user message even if one wasn't passed
    $user_message = "(no message given)" if !defined($user_message);
    
    return $toss->_retoss($user_message, $programmer_message) if(ref($toss) eq 'Toss'); # Re-Toss

    if(defined $toss && ref($toss) eq '' && $toss =~ m/\S/) { # Toss, but $toss is a string
        if($programmer_message) {
            $programmer_message .= ': $toss';
        } else {
            $programmer_message = '$toss';
        }
    }
    $toss = [{
        user_message => $user_message, #Frame level message
        time_stamp => time(),
        
        #TODO: Theoretically a re-toss will trap those message locations too.
        trace => Devel::StackTrace->new,
    }];
    
    
    $toss->[0]->{programmer_message} = $programmer_message
        if(defined $programmer_message);

    bless($toss, __PACKAGE__);
    return;
}

=head2 tossdie

Quick workaround for loss of toss information across eval boundaries. passes @_ to toss, so has same api as toss.

TODO: could we have toss() detect that it is inside a die/eval context
and change it's return convention accordingly? Right now I don't know how to do this. Ideas are welcome.

=cut

sub tossdie {
    toss(@_);
    return $toss;
}

=head2 message

Called with a number to specify which user message to display in the toss stack

    $toss->message(3) # Displays the user message from the third time toss was called when being passed down the stack.

These 2 are equivalent:

    $toss->message(0) eq $toss->message;

=cut

sub message {shift->_get_toss_frame(shift, 'user_message')}

=head2 stack

Same calling protocol as message but returns the call stack from where toss was called

=cut

sub stack{shift->_get_toss_frame(shift, 'trace')->as_string}

=head2 developer

Same calling protocol as message but returns the developer message from that paticular toss

=cut

sub developer {shift->_get_toss_frame(shift, 'programmer_message')}

=head2 time_stamp

Same calling protocol as message but returns a DateTime object from that paticular toss.


=cut

sub time_stamp {
    my $time = shift->_get_toss_frame(shift, 'time_stamp');
    return DateTime->from_epoch( epoch => $time);
}

=begin private 

=head2 _get_toss_frame

Used by stack, developer, time_stamp, message to return the appropriate part of the object's data.

=end private

=cut

sub _get_toss_frame {
    my $self = shift;
    my $stack_level = shift;
    $stack_level = 0 if(!$stack_level);
    my $item = shift;
    
    return $self->[$stack_level]->{$item}
}


=head2 _stringify

Called when you do "$toss". It appends all user messages from tosses into 1 string.

NOTE: There is no good reason to call this: "$toss" eq $toss->_stringify

=cut

sub _stringify {
    my $self = shift;

    my @toss_frames = @{$self};
    
    # Don't put the fancy numbering on if there's only one toss frame
    return $toss_frames[0]->{user_message} 
        if(scalar @toss_frames <= 1);
   

    my $return_message = '';
    my $counter = 0;
    foreach my $frame (@toss_frames) {
        $counter++;
        my $user_msg = $frame->{user_message};
        chomp $user_msg;
        $return_message .= "$counter: $user_msg\n";
    }
    (ref($return_message) eq '') or die("Not returning a string!!");
    
    chomp $return_message;
    return $return_message;
}

=head2 _retoss (private sub)

Called by toss whenever $toss is already a Toss object. It appends a toss hash onto the object's array to trap additional information

NOTE: There is no reason I can think of to call this. 
If you can think of one, please open a ticket (see below) so we can consider making the interface public.

=cut

sub _retoss {
    my $self = shift;
    my $user_message = shift;
    my $programmer_message = shift;
    
    my $toss_frame = {
        user_message => $user_message,
        time_stamp => time()
    };
    
    $toss_frame->{trace} = Devel::StackTrace->new;
    
    $toss_frame->{programmer_message} = $programmer_message
            if(defined $programmer_message);
    push @{$self}, $toss_frame;

    return; # Assure toss is undef
}


=head1 AUTHOR

Todd Rinaldo, C<< <toddr at null.net> >>

=head1 BUGS

TODO: Need to document how to gen github tickets by email and/or web.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toss


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Toss>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Toss>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Toss>

=item * Search CPAN

L<http://search.cpan.org/dist/Toss/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Todd Rinaldo, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Toss

