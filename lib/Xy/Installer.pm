package Xy::Installer;

=head2

=head3 PACKAGE		Xy::Installer

=head3 PURPOSE
    
	1. INSTALL THE DEPENDENCIES FOR Agua
	
	2. CREATE THE REQUIRED DIRECTORY STRUCTURE

	<INSTALLDIR>/bin
				cgi-bin  --> /var/www/cgi-bin/<URLPREFIX>
				   conf --> <INSTALLDIR>/conf
				   lib --> <INSTALLDIR>/lib
				   sql --> <INSTALLDIR>/bin/sql
				conf
				html --> /var/www/html/<URLPREFIX>
				lib
				t

=head3 LICENCE

This code is released under the MIT license, a copy of which should
be provided with the code.

=end pod

=cut

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();
our $AUTOLOAD;

#### EXTERNAL MODULES
use Data::Dumper;
use FindBin qw($Bin);
use lib "$Bin/lib";

use File::Copy::Recursive;
use File::Path;
use JSON;
use Term::ReadKey;

#### SET SLOTS
our @DATA =
qw(
TARGET
URLPREFIX
INSTALLDIR
DATABASE
APACHEDIR
DOMAINNAME
USERDIR
WWWDIR
WWWUSER
LOGFILE
NEWLOG
);
our $DATAHASH;
foreach my $key ( @DATA )	{	$DATAHASH->{lc($key)} = 1;	}

sub upgrade {
    my $self	=	shift;

    #### SET INSTALLDIR TO SIMPLEST PATH
    $self->setInstalldir();

    ### OPEN LOG
    $self->openLogfile();

    ## LINK INSTALLATION DIRECTORIES TO WEB DIRECTORIES
    $self->linkDirectories();
    
    ### SET PERMISSIONS TO ALLOW ACCESS BY www-data USER
    $self->setPermissions();
	
    ### CONFIRM INSTALLATION AND PRINT INFO
    $self->installConfirmation();
}

sub install {
    my $self	=	shift;

    #### SET INSTALLDIR TO SIMPLEST PATH
    $self->setInstalldir();
    
    #### UPDATE APT-get
    $self->updateAptGet();
    
    #### INSTALL EC2-API-TOOLS
    $self->installEc2();
    
    #### INSTALL MYSQL --SKIP IF INSTALLED BY DEFAULT
    $self->installMysql();
    
    ## LINK INSTALLATION DIRECTORIES TO WEB DIRECTORIES
    $self->linkDirectories();
    
    ### SET PERMISSIONS TO ALLOW ACCESS BY www-data USER
    $self->setPermissions();
	
    #### INSTALL CURL
    $self->installPackage("curl");
    
	#### INSTALL libxml2-dev
	$self->installPackage("libxml2-dev");
	
    #### INSTALL cpanminus
    $self->runCommands(["curl -L http://cpanmin.us | perl - App::cpanminus"]);
    
    ### APACHE
    $self->installApache();
	
    #### INSTALL PERL DOC
    $self->installPackage("perl-doc");
    
    #### INSTALL PERL MODS
    $self->installPerlMods();
        
    #### CONFIRM INSTALLATION AND PRINT INFO
    $self->installConfirmation();
}

#### COPY CONFIG FILE
sub copyConf {
#### COPY default.conf FILE FROM RESOURCES TO conf DIR
    my $self	=	shift;

    #my $configfile = "default.conf";
    my $configfile = "config.yaml";

    my $confdir = "$Bin/../../conf";
    my $resourcedir = "$Bin/resources/agua/conf";
    my $sourcefile = "$resourcedir/$configfile";
    my $targetfile = "$confdir/$configfile";
    print "Installer::copyConf    Copying conf file to: $targetfile\n";
    $self->backupFile($targetfile) if -f $targetfile;
    
    #### COPY
    my $command = "cp -f $sourcefile $targetfile";
    print "command: $command\n";
    `$command`;
}


sub setInstalldir {
    my $self		=	shift;
    
    my $installdir = $self->get_installdir();
    $installdir = $self->reducePath($installdir);
    $self->set_installdir($installdir);
}

sub reducePath {
	my $self		=	shift;
	my $path		=	shift;
	while ( $path =~ s/\/[^\/]+\/\.\.//g ) {
		#### reducing
	}
	
	return $path;
}


#### APT-GET
sub updateAptGet {
		my $self		=	shift;
		
	$self->runCommands([
		"apt-get update -y"
		, "apt-get upgrade -y"
	])
}
#### HTTPS
sub enableHttps {
    my $self			=   shift;
	print "Xy::Installer::enableHttps    Xy::Installer::enableHttps()\n";

	print "Xy::Installer::init    Doing generateCACert()\n";
	$self->generateCACert();
	
	print "Xy::Installer::init    Doing enableApacheSsl()\n";
	$self->enableApacheSsl();

	print "Xy::Installer::init    Doing restartHttpd()\n";
	$self->restartHttpd();	
}

sub generateCACert {
=head2

	SUBROUTINE 		generateCACert
	
	PURPOSE
	
		GENERATE AUTHENTICATED CERTIFICATE FILE USING GIVEN PRIVATE KEY
		
		AND COPY TO APACHE conf DIR
		
		(NB: MUST RESTART APACHE TO USE NEW PUBLIC CERT)


	NOTES
	
		1. GET DOMAIN NAME
		
		2. CREATE CONFIG FILE
		
		3. GENERATE CERTIFICATE REQUEST
		
			openssl req
		
		4. GENERATE PUBLIC CERTIFICATE

			openssl x509 -req

		5. COPY TO APACHE AND RESTART APACHE

		NB: APACHE ssl.conf FILE SHOULD LOOK LIKE THIS:

			...		
			SSL Virtual Hosts
			<IfDefine SSL>
			
			<VirtualHost _default_:443>
			ServerAdmin webmaster@domain.com
			...
			SSLEngine on
			SSLCertificateFile /etc/httpd/conf/ssl.crt/server.crt
			SSLCertificateKeyFile /etc/httpd/conf/ssl.key/server.key
			SetEnvIf User-Agent ".*MSIE.*" nokeepalive ssl-unclean-shutdown
			CustomLog /var/log/httpd/ssl_request_log \
				"%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b"
			</VirtualHost>
			
			</IfDefine>
			...

=cut
    my $self		=   shift;

	#### SET FILES
	my $configdir			=	"$Bin/../../conf/.https";
	my $pipefile			=	"$configdir/intermediary.pem";
	my $CA_certfile			=	"$configdir/CA-cert.pem";
	my $configfile			=	"$configdir/config.txt";
	my $privatekey			=	"$configdir/id_rsa";

	#### MAKE DIRECTORY
	print "Xy::Installer::generateCACert    configdir: $configdir\n";
	File::Path::mkpath($configdir) if not -d $configdir;
	print "Xy::Installer::generateCACert    Could not create https configdir: $configdir\n" and return if not -d $configdir;
	
	#### INSTALL APACHE SSL MODULE
    #### $self->installPackage("libapache2-mod-ssl");
    #### DEPRECATED: mod_ssl ALREADY INSTALLED IN APACHE2-COMMON PACKAGE
	#### ENABLE THE MODULE IN APACHE SERVER
    my $a2enmod = "a2enmod ssl";
    $self->runCommands([$a2enmod]);
	
	#### 1. CREATE A PRIVATE KEY
	my $remove = "rm -fr $privatekey*";
	print "Xy::Installer::generateCACert    remove: $remove\n";
	`$remove`;
	my $command = qq{cd $configdir; ssh-keygen -t rsa -f $privatekey -q -N ''};
	print "Xy::Installer::generateCACert    command: $command\n";
	print `$command`;	

	#### 2. GET DOMAIN NAME
	my $domainname = $self->getDomainName();
	print "Xy::Installer::generateCACert    domainname: $domainname\n";
	my $distinguished_name 	= 	"agua_" . $domainname . "_DN";

	#### 3. GET APACHE INSTALLATION LOCATION
	my $apachedir 	= 	$self->get_apachedir();

	#### 4. CREATE CONFIG FILE
	open(OUT, ">$configfile") or die "Can't open configfile: $configfile\n"; 	
	print OUT qq{# SSL server cert/key parms
# Cert extensions
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always,issuer:always
basicConstraints        = CA:false
nsCertType              = server
# openssl req
[req]
default_bits            = 1024
prompt                  = no
distinguished_name      = $distinguished_name
# DN fields for SSL Server cert
[$distinguished_name]
C                       = US
ST                      = Maryland
O                       = UMCP/OIT/TSS/EIS
CN                      = $domainname
emailAddress            = trash\@trash.com
};
	close(OUT) or die "Can't close configfile: $configfile\n";

	#### 3. GENERATE CERTIFICATE REQUEST
	chdir($configdir);
	my $request = qq{openssl \\
req \\
-config $configfile \\
-newkey rsa:1024 \\
-key $privatekey \\
-out $pipefile
};
	print "Xy::Installer::generateCACert    request: $request\n";
	`$request`;
	print "Xy::Installer::generateCACert    Can't find pipefile: $pipefile\n" and return if not -f $pipefile;

	#### 4. GENERATE PUBLIC CERTIFICATE
	chdir($configdir);
	my $certify = qq{openssl \\
x509 -req \\
-extfile $configfile \\
-days 730 \\
-signkey $privatekey \\
-in $pipefile \\
-out $CA_certfile
};
	print "Xy::Installer::generateCACert    certify: $certify\n";
	`$certify`;
	print "Xy::Installer::generateCACert    Can't find CA_certfile: $CA_certfile\n" if not -f $CA_certfile;

	#### COPY THE PRIVATE KEY AND CERTIFICATE TO APACHE
	my $keydir = "$apachedir/ssl.key";
	print "Xy::Installer::generateCACert    keydir: $keydir\n";
	File::Path::mkpath($keydir) if not -d $keydir;
	print "Xy::Installer::generateCACert    Can't create keydir: $keydir\n"
		if not -d $keydir;
	my $certdir = "$apachedir/ssl.key";
	File::Path::mkpath($certdir) if not -d $certdir;
	print "Xy::Installer::generateCACert    Can't create certdir: $certdir\n"
		if not -d $certdir;
	
	my $copyprivate = "cp -f $privatekey $keydir/server.key";
	print "Xy::Installer::generateCACert    copyprivate: $copyprivate\n";
	`$copyprivate`;

	my $copypublic = "cp -f $CA_certfile $certdir/server.crt";
	print "Xy::Installer::generateCACert    copypublic: $copypublic\n";
	`$copypublic`;
}

sub enableApacheSsl {
    my $self		=   shift;

	$| = 1;
	
	#### ENABLE SSL MODULE
	my $command = "a2enmod ssl";
	print "Xy::Installer::enableApacheSsl    command: $command\n";
	`$command`;
	
	#### COPY SSL CONFIG FILE
	my $installdir 	= 	$self->get_installdir();
	print "Xy::Installer::enableApacheSsl    installdir: $installdir\n";
	$command = "cp $Bin/resources/apache2/sites-available/default-ssl /etc/apache2/sites-available/default-ssl";
	print "Xy::Installer::enableApacheSsl    command: $command\n";
	`$command`;
}

sub restartHttpd {
=head2

	SUBROUTINE		restartHttpd
	
	PURPOSE
	
		START THE HTTPD SERVER

=cut
    my $self		=   shift;

	my $apachebinary	=	"/etc/init.d/apache2";
    my $restart_command = "$apachebinary restart";
	print "Xy::Installer::restartHttpd    restart_command: $restart_command\n";
	print `$restart_command`;
}

sub getDomainName {
	my $self		=	shift;
	
	my $domainname = $self->get_domainname();
	$domainname = `curl -s http://169.254.169.254/latest/meta-data/public-hostname` if not defined $domainname or not $domainname;
	$domainname = `hostname` if not defined $domainname or not $domainname;
	chomp($domainname);

	return $domainname;
}

#### INSTALL APACHE
sub installApache {
    my $self		=	shift;

    #### INSTALL APACHE2
    print "Xy::Installer::installApache    Installing apache2\n";	
    $self->installPackage("apache2");
    print "Xy::Installer::installApache    Completed installing apache2\n";	
    
    #### REPLACE mpm-worker WITH mpm-prefork (Non-threaded) CGI DAEMON
    #### TO AVOID THIS ERROR: 'unable to connect to cgi daemon'
    $self->removePackage("apache2-mpm-prefork");
    $self->installPackage("apache2-prefork-dev");
    
    #### INSTALL FASTCGI
	$self->installFastCgi();

    #### CREATE www DIRS
    $self->createWwwDirs();
 
    #### LINK DIRS INSIDE www DIRS
	$self->linkWwwDirs();
	
	#### REPLACE apache2.conf, sites-available/default AND envvars
	$self->replaceApacheConfs();

    #### COPY FAVICON
	$self->copyFavicon();
    
    #### START APACHE
    print "Xy::Installer::installApache    Starting apache\n";
    $self->runCommands(["service apache2 restart"]);
}

sub setApacheAutoStart {
#### SET COMMANDS TO BE RUN AT STARTUP FROM STARTUP SCRIPT
    my $self		=	shift;
    my $startupfile	=	shift;

    $startupfile = "/etc/init.d/rc.local" if not defined $startupfile;
    print "Xy::Installer::setApacheAutoStart    startupfile", $startupfile;

    my $command = "/etc/init.d/apache2 restart";
    my $contents = $self->fileContents($startupfile);
    $contents .="\n$command\n" if not $contents =~ /$command/ms;

    $self->toFile($startupfile, $contents);	
}

sub installFastCgi {
	my $self		=	shift;
    print "Agua::Installer::installFastCgi    Installing FASTCGI\n";

	$self->replaceSourcesList();
	$self->updateAptGet();
    $self->installPackage("libapache2-mod-fastcgi");
    my $command = "a2enmod fastcgi actions";
    $self->runCommands([$command]); 	
}

sub replaceSourcesList {
#### LATER: centos /etc/yum.conf AND /etc/yum.repos.d/*
    my $self		=	shift;

	my $arch = $self->getArch();
	return if not $arch eq "ubuntu";
	
	my $version = $self->getUbuntuVersion();
	print "Agua::Installer::replaceSourcesList    version: $version\n";		
	my $sourcefile = "$Bin/resources/ubuntu/$version/sources.list";
	
    #### REPLACE /etc/apt/sources.list
    $self->backupFile("/etc/apt/sources.list", "/etc/apt/sources.list.ORIGINAL");
    $self->replaceFile("/etc/apt/sources.list", $sourcefile, 1);   
}

sub createWwwDirs {
    my $self		=	shift;

    my $wwwdir = $self->get_wwwdir();
    $self->createDir("$wwwdir/html");
    $self->createDir("$wwwdir/cgi-bin");
}

sub linkWwwDirs {
#### LINK DIRS INSIDE www DIRS
	my $self		=	shift;

    my $linksfile	=	"$Bin/resources/agua/links.txt";
    print "Xy::Installer::linkWwwDirs   linksfile: $linksfile\n";
    my $contents = $self->fileContents($linksfile);
    print "Xy::Installer::linkWwwDirs   linksfile is empty: $linksfile\n" if not defined $contents or not $contents;
    
    my $installdir 	= 	$self->get_installdir();
    my $wwwdir 		= 	$self->get_wwwdir();
    my $urlprefix 	= 	$self->get_urlprefix();
    my @lines 	= split "\n", $contents;
    foreach my $line ( @lines ) {
		next if $line =~ /^#/ or $line =~ /^\s*$/;
    	$line =~ s/INSTALLDIR/$installdir/g;
    	$line =~ s/WWWDIR/$wwwdir/g;
    	$line =~ s/URLPREFIX/$urlprefix/g;
		my ($source, $target) = $line =~ /^(\S+)\s+(\S+)/;
	    $self->removeLink($source, $target);
	    $self->addLink($source, $target);
    }
}

sub replaceApacheConfs {
#### REPLACE apache2.conf, sites-available/default AND envvars
    my $self		=	shift;

    #### REPLACE /etc/apache2/apache2.conf
    $self->backupFile("/etc/apache2/apache2.conf", "/etc/apache2/apache2.conf.ORIGINAL");
    $self->replaceFile("/etc/apache2/apache2.conf", "$Bin/resources/apache2/apache2.conf", 1);
    
    #### REPLACE /etc/apache2/sites-available/default TO:
    #### 1. SET HTML ROOT
    #### 2. ENABLE CGI-BIN
    #### 3. ALLOW FOLLOW SYMLINKS IN CGI-BIN (AVOID ERROR: 'method PUT not allowed')
    $self->backupFile("/etc/apache2/sites-available/default", "/etc/apache2/sites-available/default.ORIGINAL");
    $self->replaceFile("/etc/apache2/sites-available/default", "$Bin/resources/apache2/sites-available/default", 1);
    
    #### REPLACE /etc/apache2/envvars TO:
    #### 1. SET UMASK (DEFAULT 775/664 FOR NEW FILES/DIRS)
    #### 2. SET SGE ENVIRONMENT VARIABLES
    $self->backupFile("/etc/apache2/envvars", "/etc/apache2/envvars.ORIGINAL");
    $self->replaceFile("/etc/apache2/envvars", "$Bin/resources/apache2/envvars", 1);
}

sub copyFavicon {
    my $self		=	shift;

    my $wwwdir 		= 	$self->get_wwwdir();
    my $installdir 	= 	$self->get_installdir();

	my $favicon = "$installdir/html/favicon.ico";
    $self->runCommands(["cp $favicon $wwwdir"]);
}

#### INSTALL APPS
sub installEc2 {
#### INSTALL ec2-api-tools
    my $self		=	shift;
	return $self->installPackage("ec2-api-tools");
}

sub installR {
#### INSTALL R STATISTICAL SOFTWARE PACKAGE
    my $self		=	shift;
    $self->installPackage("r-base");
}

#### MYSQL
sub installMysql {
    my $self		=	shift;

    print "Xy::Installer::installMysql    Xy::Installer::installMysql()\n";
    $self->installPackage("mysql-server");
    $self->installPackage("mysql-client");
    $self->installPackage("libmysqlclient16-dev libmysqlclient-dev");
    $self->installPackage("mysql-config");
    
    ##### START MYSQL AUTOMATICALLY AT BOOT
    $self->runCommands(["update-rc.d -f mysql defaults"]);

    #### ENABLE 'LOAD DATA'
    my $insert = qq{#### ENABLE load data infile
[mysqld]
local-infile=1

[mysql]
local-infile=1
};
    my $configfile = "/etc/mysql/my.cnf";
	print "Xy::Installer::installMysql    Inserting into $configfile:\n$insert\n\n";
    `echo '$insert' >> $configfile`;

    #### RESTART MYSQL
    $self->runCommands(["service mysql restart"]);
}

#### PERL MODS
sub installPerlMods {
    my $self			=	shift;

    my $perlmodsfile	=	"$Bin/resources/agua/perlmods.txt";
    print "Xy::Installer::installPerlMods    perlmodsfile: $perlmodsfile\n";
    my $contents = $self->fileContents($perlmodsfile);
    print "Xy::Installer::installPerlMods    perlmodsfile is empty: $perlmodsfile\n" if not defined $contents or not $contents;
    
    #### INSTALL MODULES IN LIST
    my @modules = split "\n", $contents;
    foreach my $module ( @modules )
    {
        next if $module =~ /^#/;
		print "Xy::Installer::installPerlMods    installing module: $module\n";
    	print "Xy::Installer::installPerlMods    Problem installing module $module\n" if not $self->cpanminusInstall($module);
    }
}

sub createDir {
    my $self		=	shift;
    my $directory	=	shift;
    print "Xy::Installer::createDir    Xy::Installer::createDir(directory)\n";


    print "Xy::Installer::createDir    directory not defined\n" if not defined $directory;
    print "Xy::Installer::createDir    directory is a file: $directory\n" if -f $directory;
    return if -d $directory;
    
    print `mkdir -p $directory`;
    print "Xy::Installer::createDir    Can't create directory: $directory\n" if not -d $directory;
}

#### INSTALL UTILS
sub replaceFile {
    my $self			=	shift;
    my $originalfile 	=	shift;
    my $replacementfile	=	shift;
    my $force			=	shift;

    $self->backupFile($originalfile, "$originalfile.bkp", 1);

    print "Xy::Installer::replaceFile    originalfile: $originalfile\n";
    print "Xy::Installer::replaceFile    replacementfile: $replacementfile\n";
    print "Xy::Installer::replaceFile    force: $force\n" if defined $force;
    
    print "Xy::Installer::replaceFile    originalfile not defined\n" if not defined $originalfile;
    print "Xy::Installer::replaceFile    replacementfile not defined\n" if not defined $replacementfile;
    print "Xy::Installer::replaceFile    Can't find replacementfile: $replacementfile\n" if not -f $replacementfile;
    print "Xy::Installer::replaceFile    Skipping as originalfile already exists: : $originalfile\n" and return if -f $originalfile and not defined $force;
    
    return if not defined $originalfile or not $originalfile;
    return if not defined $replacementfile or not $replacementfile;
    return if not -f $replacementfile;
    
    my ($originaldir) = $originalfile =~ /^(.+?)\/[^\/]+$/;
    print "Xy::Installer::replaceFile    Creating originaldir: $originaldir\n";
    if ( not -d $originaldir )
    {
    	my $command = "mkdir -p $originaldir";
    	print "Xy::Installer::replaceFile    command: $command\n";
    	print `$command`;
    	print "Xy::Installer::replaceFile    Can't create originaldir: $originaldir\n" if not -d $originaldir;
    }
    
    my $command = "cp $replacementfile $originalfile";
    print "Xy::Installer::replaceFile    command: $command\n";
    `$command`;
}

sub backupFile {
    my $self			=	shift;
    my $originalfile 	=	shift;
    my $backupfile 		=	shift;
    my $force			=	shift;

    print "Xy::Installer::backupFile    Installer::backupfile(originalfile, backupfile, force)\n";
    print "Xy::Installer::backupFile    originalfile: $originalfile\n";
	print "Xy::Installer::backupFile    backupfile: $backupfile\n";
	print "Xy::Installer::backupFile    force: $force\n" if defined $force;
	print "Xy::Installer::backupFile    Skipping backup as originalfile not present: $originalfile\n" and return if not -f $originalfile;

    print "Xy::Installer::backupFile    originalfile not defined\n" if not defined $originalfile;
    print "Xy::Installer::backupFile    backupfile not defined\n" if not defined $backupfile;
    print "Xy::Installer::backupFile    Skipping backup as backupfile already exists: : $backupfile\n" and return if -f $backupfile and not defined $force;

    my ($backupdir) = $backupfile =~ /^(.+?)\/[^\/]+$/;
    print "Xy::Installer::replaceFile    Creating backupdir: $backupdir\n";
    if ( not -d $backupdir )
    {
    	my $command = "mkdir -p $backupdir";
    	print "Xy::Installer::backupFile    command: $command\n";
    	print `$command`;
    	print "Xy::Installer::backupFile    Can't create backupdir: $backupdir\n" if not -d $backupdir;
    }
    my $command = "cp $originalfile $backupfile";
    print "Xy::Installer::backupFile    command: $command\n";
    print `$command`;
}


sub installPackage  {
    my $self		=	shift;
    my $package     =   shift;

    print "Xy::Installer::installPackage    Xy::Installer::installPackage(package)\n";
    return 0 if not defined $package or not $package;
    print "Xy::Installer::installPackage    package: $package\n";
    
    if ( -f "/usr/bin/apt-get" )
    {
    	$self->runCommands([
    	"rm -fr /var/lib/dpkg/lock",
    	"dpkg --configure -a",
    	"rm -fr /var/cache/apt/archives/lock"
    	]);

    	$ENV{'DEBIAN_FRONTEND'} = "noninteractive";
    	my $command = "/usr/bin/apt-get -q -y install $package";
    	print "Xy::Installer::installPackage    command: $command\n";
    	system($command);
    	#die("Problem with command: $command\n$!\n") if $!;
    }
    elsif ( -f "/usr/bin/yum" )
    {
    	my $command = "/usr/bin/yum -y install $package";
    	print "Xy::Installer::installPackage    command: $command\n";
    	system($command);
    	#die("Problem with command: $command\n$!\n") if $!;
    }    
}

sub removePackage  {
    my $self		=	shift;
    my $package     =   shift;

    print "Xy::Installer::removePackage    Xy::Installer::removePackage(package)\n";
    return 0 if not defined $package or not $package;
    print "Xy::Installer::removePackage    package: $package\n";
    
    if ( -f "/usr/bin/apt-get" )
    {
    	$self->runCommands([
    	"rm -fr /var/lib/dpkg/lock",
    	"dpkg --configure -a",
    	"rm -fr /var/cache/apt/archives/lock"
    	]);

    	$ENV{'DEBIAN_FRONTEND'} = "noninteractive";
    	my $command = "/usr/bin/apt-get -q -y --purge remove $package";
    	print "Xy::Installer::removePackage    command: $command\n";
    	system($command);
    	#die("Problem with command: $command\n$!\n") if $!;
    }
    elsif ( -f "/usr/bin/yum" )
    {
    	my $command = "/usr/bin/yum -y remove $package";
    	print "Xy::Installer::removePackage    command: $command\n";
    	system($command);
    	#die("Problem with command: $command\n$!\n") if $!;
    }    
}



sub cpanInstall {
        my $self		=	shift;
        my $module =    shift;
        my $logfile =    shift;
    
        print "Xy::Installer::cpanInstall    Xy::Installer::cpanInstall(module)\n";
        print "Xy::Installer::cpanInstall    module: $module\n";
        print "Xy::Installer::cpanInstall    logfile: $logfile\n" if defined $logfile;
        return 0 if not defined $module or not $module;
    
        my $command = "PERL_MM_USE_DEFAULT=1 /usr/bin/perl -MCPAN -e 'install $module'";
        $command .= " &>> $logfile"  if defined $logfile;
        print "Xy::Installer::cpanInstall    command: $command\n";
        print `$command`;
}

sub cpanminusInstall {
        my $self		=	shift;
        my $module 		=    shift;
        return 0 if not defined $module or not $module;
        
		my $cpanm = "/usr/local/bin/cpanm";
		$cpanm = "/usr/bin/cpanm" if not -f $cpanm;
		my $command = "$cpanm $module";
		
        print `$command`;
}



#### LINK DIRECTORIES
sub linkDirectories {
    my $self		=	shift;

   my $installdir  =   $self->get_installdir();
    my $wwwdir      =   $self->get_wwwdir();
    my $urlprefix	=	$self->get_urlprefix();

    print "Xy::Installer::linkDirectories    installdir not defined or empty\n" if not defined $installdir or not $installdir;
    print "Xy::Installer::linkDirectories    wwwdir not defined or empty\n" if not defined $wwwdir or not $wwwdir;
    print "Xy::Installer::linkDirectories    urlprefix not defined or empty\n" if not defined $urlprefix or not $urlprefix;

    #### REMOVE EXISTING LINKS
    my $linksfile=	"$Bin/resources/agua/links.txt";
    print "Xy::Installer::linkDirectories    Agua::Installer::linkDirectories(linksfile)\n";
    print "Xy::Installer::linkDirectories    linksfile: $linksfile\n";
    my $contents = $self->fileContents($linksfile);
    print "Xy::Installer::linkDirectories    linksfile is empty: $linksfile\n" if not defined $contents or not $contents;

    my @commands 	= split "\n", $contents;
    foreach my $command ( @commands )
    {
    	next if $command =~ /^#/ or $command =~ /^\s*$/;
    	$command =~ s/INSTALLDIR/$installdir/g;
    	$command =~ s/WWWDIR/$wwwdir/g;
    	$command =~ s/URLPREFIX/$urlprefix/g;
    	print "$command\n";

		my ($source, $target)	=	 $command =~ /^\s*(\S+)\s+(\S+)/;
		
	    $self->removeLink($target);
		$self->addLink($source, $target);
    }
	
    print "Xy::Installer::linkDirectories    Completed\n"
}

#### SET PERMISSIONS
sub setPermissions {
    my $self		=	shift;

    my $permissionsfile=	"$Bin/resources/agua/permissions.txt";
    print "Xy::Installer::setPermissions    Xy::Installer::setPermissions(permissionsfile)\n";
    print "Xy::Installer::setPermissions    permissionsfile: $permissionsfile\n";
    my $contents = $self->fileContents($permissionsfile);
    print "Xy::Installer::setPermissions    permissionsfile is empty: $permissionsfile\n" if not defined $contents or not $contents;
    
    my $installdir 	= $self->get_installdir();
	my $wwwuser 	= $self->get_wwwuser();
	my $userdir 	= $self->get_userdir();
    my @commands 	= split "\n", $contents;
    foreach my $command ( @commands )
    {
    	$command =~ s/INSTALLDIR/$installdir/g;
    	$command =~ s/WWWUSER/$wwwuser/g;
    	$command =~ s/USERDIR/$userdir/g;
    	print "$command\n";
    	next if $command =~ /^#/;
    	print `$command`;
    }
}

sub installConfirmation {
    my $self		=	shift;

    my $installdir  =   $self->get_installdir();
    my $urlprefix  	=   $self->get_urlprefix();
    my $domainname	=	$self->getDomainName();

	print qq{
    *******************************************************    
    *******************************************************

Installation directory:

    $installdir

Next, set up the mysql database:

    $installdir/bin/scripts/config.pl

};    
}


sub input {
    my $self		=	shift;
    my $message		=	shift;
    return if ( not defined $message );
    print "$message\n";	

    $/ = "\n";
    my $input = <STDIN>;
    while ( $input =~ /^\s*$/ )
    {
    	print "$message\n";
    	$input = <STDIN>;
    }	

    chop($input);
    return $input;
}

sub addLink {
    my $self		=	shift;
    my $source      =   shift;
    my $target      =   shift;
    print "Xy::Installer::addLink    source: $source\n";
    print "Xy::Installer::addLink    target: $target\n";    
    print "Xy::Installer::addLink    symlink($source, $target)\n";
	return if -l $target or -d $target or -f $target;
	
    print `ln -s $source $target`;
    print "Xy::Installer::addLink    Could not create link: $target\n" if not -l $target;
}

sub removeLink {
    my $self		=	shift;
    my $target      =   shift;
    print "Xy::Installer::removeLink    target: $target\n";

    return if not -l $target;    
    print "Xy::Installer::removeLink    unlink($target)\n";    
    unlink($target);
    print "Xy::Installer::removeLink    Could not unlink: $target\n" if -l $target;
}

sub removeDir {
    my $self		=	shift;
    my $target      =   shift;
    print "Xy::Installer::removeDir    target: $target\n";

    return if -l $target || -f $target;    
    print `$target`;
    print "Xy::Installer::removeLink    Could not remove target: $target\n" if -l $target;
}


sub yes {
    my $self		=	shift;
    my $message		=	shift;
    return if ( not defined $message );
    my $max_times = 10;
    
    $/ = "\n";
    my $input = <STDIN>;
    my $counter = 0;
    while ( $input !~ /^Y$/i and $input !~ /^N$/i )
    {
    	if ( $counter > $max_times )	{	print "Exceeded 10 tries. Exiting...\n";	}
    	
    	print "$message\n";
    	$input = <STDIN>;
    	$counter++;
    }	

    if ( $input =~ /^N$/i )	{	return 0;	}
    else {	return 1;	}
}



sub fileContents {
    my $self		=	shift;
    my $file		=	shift;

    print "Xy::Installer::contents    Xy::Installer::fileContents(file)\n";
    print "Xy::Installer::contents    file: $file\n";

    die("Xy::Installer::contents    file not defined\n") if not defined $file;
    die("Xy::Installer::contents    Can't find file: $file\n$!") if not -f $file;


    my $temp = $/;
    $/ = undef;
    open(FILE, $file) or die("Can't open file: $file\n$!");
    my $contents = <FILE>;
    close(FILE);
    $/ = $temp;
    
    return $contents;
}


sub toFile {
	my $self		=	shift;
	my $filename	=	shift;
	my $contents	=	shift;
	
	open(OUT, ">$filename") or die "Can't open filename: $filename\n";
	print OUT $contents;
	close(OUT) or die "Can't close filename: $filename\n";
}

sub backupCpanConfig {
    my $self		=	shift;
    my $configfile 		=	shift;
    print "Xy::Installer::backupCpanConfig    configfile: $configfile\n";

    return if not defined $configfile or not $configfile;
    my $backupfile = "$configfile.original"; 
    print "Xy::Installer::backupCpanConfig    backupfile: $backupfile\n";
    if ( not -f $backupfile and -f $configfile )
    {
    	my $command = "cp $configfile $backupfile";
    	print "Xy::Installer::backupCpanConfig    command: $command\n";
    	`$command`;
    }
}

sub restoreCpanConfig {
    my $self		=	shift;
    my $configfile 		=	shift;
    print "Xy::Installer::restoreCpanConfig    configfile: $configfile\n";

    return if not defined $configfile or not $configfile;
    if ( -f $configfile )
    {
    	print "Xy::Installer::restoreCpanConfig    configfile: $configfile\n";
    	my $command = "cp $configfile.original $configfile";
    	print "Xy::Installer::restoreCpanConfig    command: $command\n";
    	`$command`;
    }
}

sub replaceCpanConfig {
    my $self		=	shift;
    my $configfile 		=	shift;
    my $replacement 	=	shift;
    print "Xy::Installer::replaceCpanConfig    configfile: $configfile\n";
    print "Xy::Installer::replaceCpanConfig    replacement: $replacement\n";
    return if not defined $configfile or not $configfile;
    return if not defined $replacement or not $replacement;
    return if not -f $replacement;

    my ($configdir) = $configfile =~ /^(.+?)\/[^\/]+$/;
    print "Xy::Installer::replaceCpanConfig    Creating configdir: $configdir\n";
    if ( not -d $configdir )
    {
    	my $command = "mkdir -p $configdir";
    	print "Xy::Installer::replaceCpanConfig    command: $command\n";
    	print `$command`;
    	print "Can't create configdir: $configdir\n" if not -d $configdir;
    }

    my $command = "cp $replacement $configfile";
    print "Xy::Installer::replaceCpanConfig    command: $command\n";
    `$command`;
}




sub getfiles {
    my $self		=	shift;
    my $directory   =   shift;
    my $suffix      =   shift;
    opendir(DIR, $directory) or die "Can't open directory: $directory. $!";
    my @files = readdir(DIR);
    closedir(DIR) or die "Can't close directory: $directory. $!";
    
    return \@files if not defined $suffix;
    for ( my $i = 0; $i < $#files + 1; $i++ )
    {
        use re 'eval';
        if ( $files[$i] !~ /$suffix$/ or not -f "$directory/$files[$i]" )
        {
            splice(@files, $i, 1);
            $i--;
        }
        no re 'eval';
    }

    return \@files;
}

sub copyDirectories {
    my $self		=	shift;
    my $installdir     =   shift;
    my $directories =   shift;
    
    #### COPY ALL FILES TO BASE DIR
    print "\nCopying folders to base directory: @$directories\n";
    foreach my $directory ( @$directories )
    {
        my $sourcedir = "$Bin/../../$directory";
        print "Copying $sourcedir TO $installdir/$directory\n";
        my $targetdir = "$installdir/$directory";
        
        #### PRINT '.' AS PROGRESS COUNTER
        print ".";
    
        if ( -d $sourcedir )
        {
            my $success = File::Copy::Recursive::rcopy("$sourcedir", "$targetdir");
            if ( not $success )
            {
                die "Could not copy directory '$sourcedir' to '$targetdir': $!\n";
            }
        }
        else
        {
            die "Directory is missing from agua distribution: $sourcedir\n";
        }
    }
}


sub runCommands {
    my $self		=	shift;
    my $commands 	=	shift;
    print "Xy::Installer::runCommands    Xy::Installer::runCommands(commands)\n";
    foreach my $command ( @$commands )
    {
    	print "Xy::Installer::runCommands    command: $command\n";		
    	print `$command` or die("Error with command: $command\n$! , stopped");
    }
}

#### LOG FILE
sub openLogfile {
    my $self		=   shift;

	my $logfile 	= 	$self->get_logfile();
	print "Xy::Installer::openLogfile    Opening logfile: $logfile\n";

	#### BACK UP ANY PREVIOUS LOGFILE
	my $newlog = $self->get_newlog();
	print "Xy::Installer::openLogfile    newlog: $newlog\n" if defined $newlog;

	if ( defined $newlog )
	{
		my $backupfile = $logfile;
		$backupfile = $self->incrementFile($backupfile);
		print "Xy::Installer::openLogfile    backupfile: $backupfile\n";
		$self->backupFile($logfile, $backupfile);
	}

	#### SEND TO LOGFILE AS WELL AS STDOUT
    open (STDOUT, "| tee -ai $logfile") or die "Can't split STDOUT to logfile: $logfile\n";
	select STDOUT;
    print "Xy::Installer::openLogfile    Writing to logfile: $logfile\n";

    return $logfile;	
}

sub incrementFile {
    my $self		=	shift;
    my $logfile		=	shift;
    
    $logfile .= ".1";	
    if ( -f $logfile )
    {
    	my ($stub, $index) = $logfile =~ /^(.+?)\.(\d+)$/;
    	$index++;
    	$logfile = $stub . "." . $index;
    }

    return $logfile;    
}

sub closeLogfile {
    close (STDOUT);
}


#### MISC
sub fixGetcwd {
    my $self		=   shift;
    
    if ( not -d "/usr/bin/getcwd" )
    {
    	$self->runCommands([
    		"ln -s /bin/pwd /usr/bin/getcwd",
    		"ln -s /bin/pwd /bin/getcwd"
    	]);
    }
}

sub getArch {	
    my $self		=	shift;
    my $command = "uname -a";
    print "Xy::Installer::getArch    command: $command\n";
    my $output = `$command`;
    
    #### Linux ip-10-126-30-178 2.6.32-305-ec2 #9-Ubuntu SMP Thu Apr 15 08:05:38 UTC 2010 x86_64 GNU/Linux
    return "ubuntu" if $output =~ /ubuntu/i;
    #### Linux ip-10-127-158-202 2.6.21.7-2.fc8xen #1 SMP Fri Feb 15 12:34:28 EST 2008 x86_64 x86_64 x86_64 GNU/Linux
    return "centos" if $output =~ /fc\d+/;
    return "linux";
}

sub getUbuntuVersion {
	my $command = "cat /etc/lsb-release | grep DISTRIB_RELEASE | sed 's/DISTRIB_RELEASE=//'";
	my $version = `$command`;
	chomp($version);
	
	return $version;
}

sub getLocalTags {
	chdir($Bin);
	my $output = `git tag`;
	my @tags = split "\n", $output;
	return \@tags;
}

sub currentIteration  {
	chdir($Bin);
	my $iteration = `git log --oneline | wc -l`;
	$iteration =~ s/\s+//g;	
	$iteration = "0" x ( 5 - length($iteration) ) . $iteration;	
	return $iteration;
}

sub currentBuild  {
	chdir($Bin);
	my $build = `git rev-parse --short HEAD`;
	$build =~ s/\s+//g;
	return $build;
}

sub currentVersion  {
	my $version = `git tag -ln`;
	($version) = $version =~ /\n(\S+)[^\n]+$/;	
}
sub copyBashProfile {
    my $self		=	shift;
    $self->replaceFile("~/.bash_profile", "$Bin/resources/starcluster/.bash_profile");
}


################################################################################
##################			HOUSEKEEPING SUBROUTINES			################
################################################################################
=head2

    SUBROUTINE		initialise
    
    PURPOSE

    	INITIALISE THE self OBJECT WITH USER-INPUT ARGUMENT VALUES

=cut

sub initialise {
    my $self		=	shift;
    my $arguments	=	shift;

    #### VALIDATE USER-PROVIDED ARGUMENTS
    ($arguments) = $self->validateArguments($arguments, $DATAHASH);	
    
    #### LOAD THE USER-PROVIDED ARGUMENTS
    foreach my $key ( keys %$arguments )
    {		
    	#### LOAD THE KEY-VALUE PAIR
    	$self->loadParameterValue($key, $arguments->{$key});
    }
}

=head2

    SUBROUTINE		new
    
    PURPOSE
    
    	CREATE THE NEW OBJECT AND INITIALISE IT, FIRST WITH DEFAULT 
    	
    	ARGUMENTS, THEN WITH PROVIDED ARGUMENTS

=cut

sub new {
 	my $class 		=	shift;
    my $arguments 	=	shift;
        
    my $self = {};
    bless $self, $class;
    
    #### INITIALISE THE OBJECT'S ELEMENTS
    $self->initialise($arguments);

    return $self;
}


=head2

    SUBROUTINE		value
    
    PURPOSE

    	SET A PARAMETER OF THE self OBJECT TO A GIVEN value

    INPUT
    
        1. parameter TO BE SET
    	
    	2. value TO BE SET TO
    
    OUTPUT
    
        1. THE SET parameter INSIDE THE BioSVG OBJECT
    	
=cut
sub loadParameterValue {
    my $self		=	shift;
    my $parameter	=	shift;
    my $value		=	shift;

    $parameter = lc($parameter);
    if ( defined $value)
    {	
    	$self->{"_$parameter"} = $value;
    }
}

=head2

    SUBROUTINE		validateArguments

    PURPOSE
    
    	VALIDATE USER-INPUT ARGUMENTS BASED ON
    	
    	THE HARD-CODED LIST OF VALID ARGUMENTS
    	
    	IN THE data ARRAY
=cut

sub validateArguments {
    my $self		=	shift;
    my $arguments	=	shift;
    my $DATAHASH	=	shift;
    
    my $hash;
    foreach my $argument ( keys %$arguments )
    {
    	if ( $self->isValidArgument($argument, $DATAHASH) )
    	{
    		$hash->{$argument} = $arguments->{$argument};
    	}
    	else
    	{
    		warn "'$argument' is not a known parameter\n";
    	}
    }
    
    return $hash;
}

=head2

    SUBROUTINE		isValidArgument

    PURPOSE
    
    	VERIFY THAT AN ARGUMENT IS AMONGST THE LIST OF
    	
    	ELEMENTS IN THE GLOBAL '$DATAHASH' HASH REF
    	
=cut

sub isValidArgument {
    my $self		=	shift;
    my $argument	=	shift;
    my $DATAHASH	=	shift;
    
    #### REMOVE LEADING UNDERLINE, IF PRESENT
    $argument =~ s/^_//;
    
    #### CHECK IF ARGUMENT FOUND IN '$DATAHASH'
    if ( exists $DATAHASH->{lc($argument)} )
    {
    	return 1;
    }
    
    return 0;
}

=head2

    SUBROUTINE		AUTOLOAD

    PURPOSE
    
    	AUTOMATICALLY DO 'set_' OR 'get_' FUNCTIONS IF THE
    	
    	SUBROUTINES ARE NOT DEFINED.

=cut

sub AUTOLOAD {
    my ($self, $newvalue) = @_;
    my ($operation, $attribute) = ($AUTOLOAD =~ /(get|set)(_\w+)$/);

    # Is this a legal method name?
    unless ( defined $operation && $operation && defined $attribute && $attribute ) {
        print "Method name $AUTOLOAD is not in the recognized form (get|set)_attribute\n" and exit;
    }
    
    unless( exists $self->{$attribute} or $self->isValidArgument($attribute) )
    {
    	#if ( not defined $operation )
    	#{
            #die "No such attribute '$attribute' exists in the class ", ref($self);
    		#return;
    	#}
    }

    # Turn off strict references to enable "magic" AUTOLOAD speedup
    no strict 'refs';

    # AUTOLOAD accessors
    if($operation eq 'get') {
        # define subroutine
        *{$AUTOLOAD} = sub { shift->{$attribute} };

    # AUTOLOAD mutators
    }elsif($operation eq 'set') {
        # define subroutine4
    	
        *{$AUTOLOAD} = sub { shift->{$attribute} = shift; };

        # set the new attribute value
        $self->{$attribute} = $newvalue;
    }

    # Turn strict references back on
    use strict 'refs';

    # return the attribute value
    return $self->{$attribute};
}


=head 2

    SUBROUTINE		DESTROY
    
    PURPOSE
    
    	When an object is no longer being used, this will be automatically called
    	
    	and will adjust the count of existing objects

=cut
sub DESTROY {
    my($self) = @_;

    #### TIDY UP, DISCONNECT DATABASE HANDLES, ETC.
    $self->closeLogfile();
}




1;
