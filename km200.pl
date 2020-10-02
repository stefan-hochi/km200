#!/usr/bin/perl
use strict;
use warnings;

use lib '/root/lib';
use km200;

use LWP::UserAgent;
use HTTP::Request;
use HTTP::Cookies;
use JSON::MaybeXS qw(encode_json decode_json);
use Math::Round qw/nearest/;
use MIME::Base64 qw(encode_base64 decode_base64);

use Data::Dumper;

my $IPv4address = "192.168.2.126";
my $GatewayPassword = "GatewayPassword";
my $PrivatePassword = "PrivatePassword";

my ($hash, $def) = @_;
$def = "km200	km200	$IPv4address	$GatewayPassword	$PrivatePassword";
my $define = km200_Define(undef, $def);

my @BUDERUS_KNOWN_APIS = ("/system", "/heatingCircuits/hc1");
my $id;
for my $key (@BUDERUS_KNOWN_APIS)
{
	$hash->{Secret}{CRYPTKEYPRIVATE} = $define;
	$hash->{NAME} = "";
	$hash->{temp}{service} = $key;
	$hash->{URL} = $IPv4address;
	my $Service = km200_GetSingleService($hash);
	push @{$id}, (query({ Service => $Service }))->@*;
}

for my $test ($id->@*)
{
	print Dumper($test->{id});
	#get metric
}

sub query
{
	my $param = shift;
	my $Service = $param->{'Service'};
	my $id;
	for my $reference ($Service->{references}->@*)
	{
		$hash->{Secret}{CRYPTKEYPRIVATE} = $define;
		$hash->{NAME} = "";
		$hash->{temp}{service} = $reference->{id};
		$hash->{URL} = $IPv4address;
		my $Service = km200_GetSingleService($hash);
		push @{$id}, $Service;
	}
	return $id;
}
1;
