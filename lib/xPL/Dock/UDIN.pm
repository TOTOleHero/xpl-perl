package xPL::Dock::UDIN;

=head1 NAME

xPL::Dock::UDIN - xPL::Dock plugin for an UDIN relay module

=head1 SYNOPSIS

  use xPL::Dock qw/UDIN/;
  my $xpl = xPL::Dock->new();
  $xpl->main_loop();

=head1 DESCRIPTION

This module creates an xPL client for a serial port-based device.  There
are several usage examples provided by the xPL Perl distribution.

=head1 METHODS

=cut

use 5.006;
use strict;
use warnings;

use English qw/-no_match_vars/;
use Pod::Usage;
use xPL::Dock::SerialLine;

our @ISA = qw(xPL::Dock::SerialLine);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = qw/$Revision$/[1];

=head2 C<getopts( )>

This method returns the L<Getopt::Long> option definition for the
plugin.

=cut

sub getopts {
  my $self = shift;
  $self->{_baud} = 9600;
  return (
          'udin-verbose|udinverbose+' => \$self->{_verbose},
          'udin-baud|udinbaud=i' => \$self->{_baud},
          'udin=s' => \$self->{_device},
         );
}

=head2 C<init(%params)>

=cut

sub init {
  my $self = shift;
  my $xpl = shift;
  my %p = @_;

  $self->required_field($xpl, 'device', 'The --udin parameter is required', 1);
  $self->SUPER::init($xpl,
                     reader_callback => \&process_line,
                     ack_timeout => 0.05,
                     @_);

  # Add a callback to receive incoming xPL messages
  $xpl->add_xpl_callback(id => 'udin', callback => \&xpl_in,
                         arguments => $self,
                         filter => {
                                    message_type => 'xpl-cmnd',
                                    class => 'control',
                                    class_type => 'basic',
                                    type => 'output',
                                   });

  $self->write('?');
  return $self;
}

=head2 C<xpl_in(%xpl_callback_parameters)>

This is the callback that processes incoming xPL messages.  It handles
the incoming control.basic schema messages.

=cut

sub xpl_in {
  my %p = @_;
  my $msg = $p{message};
  my $peeraddr = $p{peeraddr};
  my $peerport = $p{peerport};
  my $self = $p{arguments};
  my $xpl = $self->xpl;

  if ($msg->device eq 'debug') {
    $self->write('s0');
  }
  return 1 unless ($msg->device =~ /^o(\d+)$/);
  my $num = $LAST_PAREN_MATCH;
  my $command = lc $msg->current;
  if ($command eq "high") {
    $self->write(sprintf("n%d", $num));
  } elsif ($command eq "low") {
    $self->write(sprintf("f%d", $num));
  } elsif ($command eq "pulse") {
    $self->write(sprintf("n%d", $num));
    #select(undef,undef,undef,0.15);
    $self->write(sprintf("f%d", $num));
  } elsif ($command eq "toggle") {
    $self->write(sprintf("t%d", $num));
  } else {
    warn "Unsupported setting: $command\n";
  }
  return 1;
}

=head2 C<process_line()>

This is the callback that processes lines of output from the UDIN.  It
is responsible for sending out the sensor.basic xpl-trig messages.

=cut

sub process_line {
  my ($self, $line) = @_;
  return unless (defined $line && $line ne '');
  $self->info("received: '$line'\n");
  return 1;
}

1;
__END__

=head1 EXPORT

None by default.

=head1 SEE ALSO

Project website: http://www.xpl-perl.org.uk/

=head1 AUTHOR

Mark Hindess, E<lt>soft-xpl-perl@temporalanomaly.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2005, 2009 by Mark Hindess

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut