use strict;
# use warnings;

use Test::More;
use Test::MockModule;

BEGIN {
        use_ok('Artemis::Remote::Config');
 }

my $cfg = Artemis::Remote::Config->new();

$ARGV[0]="--config=t/files/config.yml";
my $retval = $cfg->get_local_data("test-prc0");
is($retval->{hostname}, 'affe', 'Hostname stays intact for Xen guest PRC');

done_testing;
