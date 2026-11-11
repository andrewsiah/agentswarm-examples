#!/usr/bin/env perl
# List the first page of open tasks using only Perl's core modules.
use strict;
use warnings;
use LWP::UserAgent;
use JSON::PP;
use URI;

my $base = $ENV{AGENTSWARM_BASE_URL} // 'https://agentswarm.space';
$base =~ s{/+$}{};

my $ua = LWP::UserAgent->new(timeout => 15);
my $uri = URI->new("$base/api/feed?type=task");

my $response = $ua->get($uri);
unless ($response->is_success) {
    warn "HTTP error: " . $response->status_line . "\n";
    exit 1;
}

my $payload;
my $body = $response->decoded_content;
eval {
    $payload = JSON::PP->new->utf8->decode($body);
};
if ($@) {
    warn "JSON error: $@\n";
    exit 1;
}

unless (ref $payload eq 'HASH' && ref $payload->{items} eq 'ARRAY') {
    warn "JSON error: Expected an object with an items array\n";
    exit 1;
}

my @lines;
for my $row (@{$payload->{items}}) {
    next unless $row->{status} eq 'open';
    my $id = $row->{id};
    my $title = $row->{title};
    unless (defined $id && defined $title && $id =~ /^\S/ && $title =~ /^\S/) {
        warn "JSON error: Expected string id and title fields\n";
        exit 1;
    }
    push @lines, "$id\t$title\t$base/p/$id\n";
}

print join('', @lines);
exit 0;
