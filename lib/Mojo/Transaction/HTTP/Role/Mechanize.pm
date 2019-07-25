package Mojo::Transaction::HTTP::Role::Mechanize;

use Mojo::Base -role;
use Mojo::UserAgent::Transactor;

our $VERSION = '0.03';

requires qw{error};

sub submit {
  my $any = 'button:not([disabled]), input:matches([type=button],'
	    . ' [type=submit], [type=image]):not([disabled])';
  my ($self, $selector, $overlay) = (shift, (@_ % 2 ? shift : $any, {@_}));
  # cannot continue from error state
  return if $self->error;
  # form from selector
  return unless defined(my $form = $self->res->dom->find('form')
    ->grep(sub { $_->at($selector) })->first);
  # compose ...
  $form->with_roles('Mojo::DOM::Role::Form')
    unless Role::Tiny::does_role($form, 'Mojo::DOM::Role::Form');
  # now there is a form, rely on _form_default_submit() if we relied on $any b4.
  $selector = undef if $any eq $selector;
  return unless (my ($method, $target, $type) =
    $form->target($selector));
  $target = $self->req->url->new($target);
  $target = $target->to_abs($self->req->url) unless $target->is_abs;
  # values from form
  my $state = $form->val($selector);
  # merge in new values of form elements
  my @keys = grep { exists $overlay->{$_} } keys %$state;
  @$state{@keys} = @$overlay{@keys};

  # build a new transaction ...
  return Mojo::UserAgent::Transactor->new->tx(
    $method => $target, {}, form => $state
    );
}


1;

=encoding utf8

=begin html

<a href="https://travis-ci.com/kiwiroy/mojo-transaction-http-role-mechanize">
  <img alt="Travis Build Status"
       src="https://travis-ci.com/kiwiroy/mojo-transaction-http-role-mechanize.svg?branch=master" />
</a>

<a href="https://kritika.io/users/kiwiroy/repos/7509235145731088/heads/master/">
  <img alt="Kritika Analysis Status"
       src="https://kritika.io/users/kiwiroy/repos/7509235145731088/heads/master/status.svg?type=score%2Bcoverage%2Bdeps" />
</a>

<a href="https://coveralls.io/github/kiwiroy/mojo-transaction-http-role-mechanize?branch=master">
  <img alt="Coverage Status"
       src="https://coveralls.io/repos/github/kiwiroy/mojo-transaction-http-role-mechanize/badge.svg?branch=master" />
</a>

=end html

=head1 NAME

Mojo::Transaction::HTTP::Role::Mechanize - Mechanize Mojo a little

=head1 SYNOPSIS

  # description
  my $tx = $ua->get('/')->with_roles('+Mechanize');
  my $submit_tx = $tx->submit('#submit-id', username => 'fry');
  $ua->start($submit_tx);

=head1 DESCRIPTION

L<Role::Tiny> based role to compose a form submission I<"trait"> into
L<Mojo::Transaction::HTTP>.

=head1 METHODS

L<Mojo::Transaction::HTTP::Role::Mechanize> implements the following methods.

=head2 submit

  # result
  $submit_tx = $tx->submit('#id', username => 'fry');

Build a new L<Mojo::Transaction::HTTP> object with
L<Mojo::UserAgent::Transactor/"tx"> and the contents of the C<form> with the
C<$id> and merged values.

=head1 AUTHOR

kiwiroy - Roy Storey <kiwiroy@cpan.org>

=head1 CONTRIBUTORS

tekki - Rolf Stöckli <tekki@cpan.org>

=head1 LICENSE

This library is free software and may be distributed under the same terms as
perl itself.

=cut
