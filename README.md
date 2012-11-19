net_test
========

## Description

Test Network-related features for MANAGED and MANAGED-NOVALN Modes

## Procedure

1. Looks in 2b_tested.lst for NETWORK(space){MODE}, where {MODE} is the euca_conf VNET mode
2. [PASS] Mode is STATIC or SYSTEM - PASSING
3. Adds a keypair using euca-add-keypair
4. [FAIL] Keypair cannot be added
5. Adds 2 groups
6. [FAIL] Exit with error if either group cannot be added
7. Authorizes the first group for ssh tcp using euca-add-group
8. [FAIL] Cannot authorize
9. Gets a windows image emi number using euca-describe-images
10. [FAIL] No windows EMI
11. Run windows instance with first group and the recently added keypair euca-run-instance
12. [FAIL] Instance did not start
13. Run windows instance with second group (unauthorized) and the recently added keypair euca-run-instance
14. [FAIL] Instance did not start
15. Wait for both instances to get public IPs by checking the euca-describe-instances 600 times
16. [FAIL] An instance did not receive its IP
17. Authorize the second group for just the IP of the Public interface of the first instance
18. [FAIL] Failed to authorize
19. Check both instances for the words 'NOT SUPPORT' or 'oops' in the console using euca-get-console
20. [FAIL] SCP my the local private keys over to instance1, then from instance1 to instance2 (checks both security groups
21. Make sure localhost could not ssh to instance2
22. [FAIL] SSH block did not work



# Eucalyptus Testunit Framework

Eucalyptus Testunit Framework is designed to run a list of test scripts written by Eucalyptus developers.



## How to Set Up Testunit Environment

On **Ubuntu** Linux Distribution,

### 1. UPDATE THE IMAGE

<code>
apt-get -y update
</code>

### 2. BE SURE THAT THE CLOCK IS IN SYNC

<code>
apt-get -y install ntp
</code>

<code>
date
</code>

### 3. INSTALL DEPENDENCIES
<note>
YOUR TESTUNIT **MIGHT NOT** NEED ALL THE PACKAGES BELOW; CHECK THE TESTUNIT DESCRIPTION.
</note>

<code>
apt-get -y install git-core bzr gcc make ruby libopenssl-ruby curl rubygems swig help2man libssl-dev python-dev libright-aws-ruby nfs-common openjdk-6-jdk zip libdigest-hmac-perl libio-pty-perl libnet-ssh-perl euca2ools
</code>

### 4. CLONE test_share DIRECTORY FOR TESTUNIT
<note>
YOUR TESTUNIT **MIGHT NOT** NEED test_share DIRECTORY. CHECK THE TESTUNIT DESCRIPTION.
</note>

<code>
git clone git://github.com/eucalyptus-qa/test_share.git
</code>

### 4.1. CREATE /home/test-server/test_share DIRECTORY AND LINK IT TO THE CLONED test_share

<code>
mkdir -p /home/test-server
</code>

<code>
ln -s ~/test_share/ /home/test-server/.
</code>

### 5. CLONE TESTUNIT OF YOUR CHOICE

<code>
git clone git://github.com/eucalyptus-qa/**testunit_of_your_choice**
</code>

### 6. CHANGE DIRECTORY

<code>
cd ./**testunit_of_your_choice**
</code>

### 7. CREATE 2b_tested.lst FILE in ./input DIRECTORY

<code>
vim ./input/2b_tested.lst
</code>

### 7.1. TEMPLATE OF 2b_tested.lst, SEPARATED BY TAB

<sample>
192.168.51.85	CENTOS	6.3	64	REPO	[CC00 UI CLC SC00 WS]

192.168.51.86	CENTOS	6.3	64	REPO	[NC00]
</sample>

### 7.2. BE SURE THAT YOUR MACHINE's id_rsa.pub KEY IS INCLUDED THE CLC's authorized_keys LIST

ON **YOUR TEST MACHINE**:

<code>
cat ~/.ssh/id_rsa.pub
</code>

ON **CLC MACHINE**:

<code>
vim ~/.ssh/authorized_keys
</code>

### 8. RUN THE TEST

<code>
./run_test.pl **testunit_of_your_choice.conf**
</code>


## How to Examine the Test Result

### 1. GO TO THE artifacts DIRECTORY

<code>
cd ./artifacts
</code>

### 2. CHECK OUT THE RESULT FILES

<code>
ls -l
</code>


## How to Rerun the Testunit

### 1. CLEAN UP THE ARTIFACTS

<code>
./cleanup_test.pl
</code>

### 2. RERUN THE TEST

<code>
./run_test.pl **testunit_of_your_choice.conf**
</code>


