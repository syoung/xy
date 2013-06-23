use MooseX::Declare;
use Method::Signatures::Modifiers;

use strict;
use warnings;

#### USE LIB FOR INHERITANCE
use FindBin qw($Bin);
use lib "$Bin/../";

class Xy::DBaseFactory {

sub new {
    my $class          = shift;
    my $requested_type = shift;
    
    my $location    = "Infusion/DBase/$requested_type.pm";
    $class          = "Xy::DBase::$requested_type";
    require $location;

    return $class->new(@_);
}
    
Xy::DBaseFactory->meta->make_immutable(inline_constructor => 0);

} #### END

1;
