use strict;
use warnings;
use POSIX ":sys_wait_h";


use Test::More;
use Test::MockModule;

use Log::Log4perl;

BEGIN {
        use_ok('Tapper::Remote::Net');
 }


my $string = "
log4perl.rootLogger           = FATAL, root
log4perl.appender.root        = Log::Log4perl::Appender::Screen
log4perl.appender.root.stderr = 1
log4perl.appender.root.layout = SimpleLayout";
Log::Log4perl->init(\$string);


my $server = IO::Socket::INET->new(Listen    => 5);
ok($server, 'create socket');

my $config = {
              mcp_host => 'localhost',
              mcp_port => $server->sockport(),
             };



my $net = Tapper::Remote::Net->new($config);


my $report = {
              tests => [
                        {error => 1, test  => 'First test'},
                        { test  => 'Second test' },
                       ],
              headers => {
                          First_header => '1',
                          Second_header => '2',
                         },
             };
my $message = $net->tap_report_create($report);
like($message, qr(# First_header: 1), 'First header in tap_report_create');
like($message, qr(# Second_header: 2), 'Second header in tap_report_create');
like($message, qr(not ok 1 - First test\nok 2 - Second test), 'Tests in tap_report_create');

my $retval = $net->mcp_inform('start-install');

# testing message sending is more complex; ignore it for now
is($retval, 0, 'No error in writing status message');

done_testing;
