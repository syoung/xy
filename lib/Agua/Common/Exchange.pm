use Moose::Util::TypeConstraints;
use MooseX::Declare;
use Method::Signatures::Modifiers;


class Agua::Common::Exchange with (Agua::Common::Logger) {

use Net::RabbitFoot;
use JSON;

# Ints
has 'SHOWLOG'           => ( isa => 'Int', is => 'rw', default  =>      2       );
has 'PRINTLOG'          => ( isa => 'Int', is => 'rw', default  =>      2       );

## Objects
has 'channel'	=> ( isa => 'Net::RabbitFoot::Channel', is => 'rw', lazy	=> 1, builder => "openConnection" );

method openConnection {
	$self->logDebug("");
	my $connection = Net::RabbitFoot->new()->load_xml_spec()->connect(
		#host => 'localhost',
		host => '10.14.152.42',
		port => 5672,
		user => 'guest',
		pass => 'guest',
		vhost => '/',
	);
	
	$self->logDebug("DOING connection->open_channe()");
	my $channel = $connection->open_channel();
	$self->channel($channel);
	$self->logDebug("BEFORE channel", $channel);

	#### SET DEFAULT CHANNEL
	$self->setChannel("chat", "fanout");	
	$channel->declare_exchange(
		exchange => 'chat',
		type => 'fanout',
	);
	#$self->logDebug("channel", $channel);

	#### START RABBIT.JS
	$self->startRabbitJs();
	
	return $connection;
}

method startRabbitJs {
	
}

method setChannel($name, $type) {
	$self->channel()->declare_exchange(
		exchange => $name,
		type => $type,
	);
}

method closeConnection {
	$self->logDebug("");
	$self->connection()->close();
}

method sendMessage ($message) {
	$self->logDebug("message", $message);

	$self->openConnection() if not defined $self->connection();
	
	my $result = $self->channel()->publish(
		exchange => 'chat',
		routing_key => '',
		body => $message,
	);
	$self->logDebug(" [x] Sent message", $message);

	return $result;
}

method sendData ($data) {
	$self->logDebug("data", $data);

	my $jsonparser = JSON->new();
	my $json = $jsonparser->encode($data);
	$self->logDebug("json", $json);

	$self->logDebug("BEFORE channel->publish, self->channel", $self->channel());

	my $result = $self->channel()->publish(
		exchange => 'chat',
		routing_key => '',
		body => $json,
	);
	$self->logDebug(" [x] Sent message", $json);

	return $result;
}

};
