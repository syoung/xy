package Agua::Common::Rabbit;
use Moose::Role;
use Method::Signatures::Simple;

use Net::RabbitFoot;

# Objects
has 'connection'=> ( isa => 'Net::RabbitFoot|Undef', is => 'rw');
has 'channel'	=> ( isa => 'Int', is => 'rw', lazy	=> 1, builder => "openConnection" );

method openConnection {
	$self->logDebug("");
	my $connection = Net::RabbitFoot->new()->load_xml_spec()->connect(
		host => 'localhost',
		port => 5672,
		user => 'guest',
		pass => 'guest',
		vhost => '/',
	);
	
	my $channel = $connection->open_channel();
	$self->channel($channel);

	#### SET DEFAULT CHANNEL
	$self->setChannel("chat", "fanout");	
	$channel->declare_exchange(
		exchange => 'chat',
		type => 'fanout',
	);
	$self->logDebug("channel", $channel);
	
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

	$self->channel()->publish(
		exchange => 'chat',
		routing_key => '',
		body => $message,
	);
	$self->logDebug(" [x] Sent message", $message);

}


1;