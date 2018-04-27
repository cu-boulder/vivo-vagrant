sudo /usr/share/debconf/fix_db.pl
sudo apt-get clean
sudo apt-get -f install
sudo apt-get update -y
sudo apt-get -q -y -f build-dep dictionaries-common linux-headers-generic build-essential dkms
sudo apt-get -y install dictionaries-common linux-headers-generic build-essential dkms

sudo apt-get -q -y -f build-dep virtualbox-ose-guest-utils virtualbox-guest-x11 virtualbox-ose-guest-x11 virtualbox-ose-guest-dkms
sudo apt-get -y install virtualbox-ose-guest-utils virtualbox-guest-x11 virtualbox-ose-guest-x11 virtualbox-ose-guest-dkms
sudo apt-get -y install xfce4

