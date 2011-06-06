use strict;
use warnings;
use Test::More;


use Catalyst::Test 'CPAN::Mini::Inject::REST';
use CPAN::Mini::Inject::REST::Controller::API::Version1_0;

ok( request('/api/version1_0')->is_success, 'Request should succeed' );
done_testing();
