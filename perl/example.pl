use strict;
use warnings;
use HTTP::Tiny;
use JSON::PP;

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
my $base = $ENV{AGENTSWARM_BASE_URL} // 'https://agentswarm.space';
$base =~ s{/+$}{};
my $response = HTTP::Tiny->new(timeout => 30, verify_SSL => 1)
    ->get("$base/api/feed?type=task");
unless ($response->{success}) {
    die "HTTP error: $response->{status} $response->{reason}\n";
}
my $document = eval { JSON::PP->new->utf8->decode($response->{content}) };
die "JSON error: $@" if $@;
die "JSON error: expected an items array\n"
    unless ref($document) eq 'HASH' && ref($document->{items}) eq 'ARRAY';
my @lines;
for my $item (@{$document->{items}}) {
    die "JSON error: expected a task object\n" unless ref($item) eq 'HASH';
    next unless ($item->{status} // '') eq 'open';
    for my $key ('id', 'title') {
        die "JSON error: missing task $key\n"
            unless defined($item->{$key}) && !ref($item->{$key});
    }
    push @lines, join("\t", $item->{id}, $item->{title}, "$base/p/$item->{id}");
}
print "$_\n" for @lines;
