#!/usr/bin/perl

require "ec2ops.pl";

my $account = shift @ARGV || "eucalyptus";
my $user = shift @ARGV || "admin";
my $mode = shift @ARGV || "cidr";

# need to add randomness, for now, until account/user group/keypair
# conflicts are resolved

$rando = int(rand(10)) . int(rand(10)) . int(rand(10));
if ($account ne "eucalyptus") {
    $account .= "$rando";
}
if ($user ne "admin") {
    $user .= "$rando";
}
$newkeyp = "netkey$rando";

parse_input();
print "SUCCESS: parsed input\n";

setlibsleep(1);
print "SUCCESS: set sleep time for each lib call\n";

setremote($masters{"CLC"});
print "SUCCESS: set remote CLC: masterclc=$masters{CLC}\n";

discover_emis();
print "SUCCESS: discovered loaded image: current=$current_artifacts{instancestoreemi}, all=$static_artifacts{instancestoreemis}\n";

discover_zones();
print "SUCCESS: discovered available zone: current=$current_artifacts{availabilityzone}, all=$static_artifacts{availabilityzones}\n";

discover_userid();
print "SUCCESS: discovered userid: userid=$current_artifacts{userid}\n";

if ( ($account ne "eucalyptus") && ($user ne "admin") ) {
# create new account/user and get credentials
    create_account_and_user($account, $user);
    print "SUCCESS: account/user $current_artifacts{account}/$current_artifacts{user}\n";
    
    grant_allpolicy($account, $user);
    print "SUCCESS: granted $account/$user all policy permissions\n";
    
    get_credentials($account, $user);
    print "SUCCESS: downloaded and unpacked credentials\n";
    
    source_credentials($account, $user);
    print "SUCCESS: will now act as account/user $account/$user\n";
}

# moving on
add_keypair("$newkeyp");
print "SUCCESS: added new keypair: $current_artifacts{keypair}, $current_artifacts{keypairfile}\n";

add_group("netgroup0$rando");
print "SUCCESS: added group: $current_artifacts{group}\n";
$snetgroup = "netgroup0$rando";

authorize_ssh_from_cidr("netgroup0$rando", "0.0.0.0/0");
print "SUCCESS: authorized ssh access to VM\n";

my @zones = split(/\s+/, $static_artifacts{"availabilityzones"});
my $zonecount=0;
foreach $zone (@zones) {
    setzone($zone);
    print "SUCCESS: set current av. zone to $current_artifacts{availabilityzone}\n";

    run_instances(1);
    print "SUCCESS: ran instance: $current_artifacts{instance}\n";
    
    wait_for_instance();
    print "SUCCESS: instance went to running: $current_artifacts{instancestate}\n";
    
    wait_for_instance_ip();
    print "SUCCESS: instance got public IP: $current_artifacts{instanceip}\n";
    
    wait_for_instance_ip_private();
    print "SUCCESS: instance got private IP: $current_artifacts{instanceprivateip}\n";
    
    ping_instance_from_cc();
    print "SUCCESS: instance private IP pingable from CC: instanceip=$current_artifacts{instanceprivateip} ccip=$current_artifacts{instancecc}\n";
    
    run_instance_command("uname -a");
    print "SUCCESS: able to run command on VM\n";
    
    run_command("scp -o StrictHostKeyChecking=no -i $current_artifacts{keypairfile} $current_artifacts{keypairfile} root\@$current_artifacts{instanceip}:/root/netkey.priv");
    print "SUCCESS: copied keypair to VM\n";
    
    $firstpublicips[$zonecount] = $current_artifacts{instanceip};
    $firstprivateips[$zonecount] = $current_artifacts{instanceprivateip};
    $zonecount++;
}

add_group("netgroup1$rando");
print "SUCCESS: added group: $current_artifacts{group}\n";

$zonecount=0;
foreach $zone (@zones) {
    my $firstprivateip = $firstprivateips[$zonecount];
    my $firstpublicip = $firstpublicips[$zonecount];

    if ($mode eq "usergroup") {
	authorize_ssh_from_usergroup("netgroup1$rando", $current_artifacts{"userid"}, "$snetgroup");
    } else {
	authorize_ssh_from_cidr("netgroup1$rando", "$firstprivateip/32");
    }
    print "SUCCESS: authorized ssh access to VM\n";

    setzone($zone);
    print "SUCCESS: set current av. zone to $current_artifacts{availabilityzone}\n";

    run_instances(1);
    print "SUCCESS: ran instance: $current_artifacts{instance}\n";
    
    wait_for_instance();
    print "SUCCESS: instance went to running: $current_artifacts{instancestate}\n";
    
    wait_for_instance_ip();
    print "SUCCESS: instance got public IP: $current_artifacts{instanceip}\n";
    
    wait_for_instance_ip_private();
    print "SUCCESS: instance got private IP: $current_artifacts{instanceprivateip}\n";
    
    ping_instance_from_cc();
    print "SUCCESS: instance private IP pingable from CC: instanceip=$current_artifacts{instanceprivateip} ccip=$current_artifacts{instancecc}\n";
    $secondpublicips[$zonecount] = $current_artifacts{instanceip};
    $secondprivateips[$zonecount] = $current_artifacts{instanceprivateip};
    $zonecount++;
}

sleep (45);

$zonecount=0;
foreach $zone (@zones) {
    my $firstprivateip = $firstprivateips[$zonecount];
    my $firstpublicip = $firstpublicips[$zonecount];
    my $secondprivateip = $secondprivateips[$zonecount];
    my $secondpublicip = $secondpublicips[$zonecount];

    $oldrunat = $runat;
    setrunat("runat 120");
    run_command("ssh -o StrictHostKeyChecking=no -i $current_artifacts{keypairfile} root\@$firstpublicip 'ssh -o StrictHostKeyChecking=no -i /root/netkey.priv root\@$secondprivateip uname -a'");
    print "SUCCESS: able to access second VM from within first VM\n";
    setrunat("$oldrunat");

    run_command_not("scp -o StrictHostKeyChecking=no $current_artifacts{keypairfile} root\@$secondpublicip:/root/netkey.priv");
    print "SUCCESS: unable to copy keypair to firewalled VM\n";
    $zonecount++;
}
doexit(0, "EXITING SUCCESS\n");
