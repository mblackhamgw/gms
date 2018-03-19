
import os, sys, logging, socket
from subprocess import Popen, PIPE
from time import sleep
import rpm
from glob import glob




class GMSINSTALL:

    def __init__(self):
        self.scriptDir = os.getcwd()
        print 'Runding install.py from %s' %self.scriptDir

    def whoami(self):
        user = self.getuser()
        self.logit('Welcome to the Micro Focus GroupWise Mobility Service install.')
        self.logit('You are logged in as root')
        login = self.getuser()
        if login != 0:
            print "You should have root permissions to execute this script."
            sys.exit(1)

    def getrpminfo(self):

        '''
        List the packages currently installed in a dict::

            {'<package_name>': '<epoch>:<version>-<release>.<arch>'}

        CLI Example:

            .. code-block:: bash

                salt '*' rpmlibpkg.list_pkgs
        '''
        ts = rpm.TransactionSet()
        mi = ts.dbMatch()
        epoch = lambda h: "%s:" % h['epoch'] if h['epoch'] else ''
        pkgs = dict([
            (h['name'], "%s%s-%s.%s" % (
                epoch(h), h['version'], h['release'], h['arch']))
            for h in mi])

        #for key, value in pkgs.iteritems():
        #    if key == rpmname:
        #        return '%s-%s' % (key, pkgs[key])

        return pkgs

    def getuser(self):
        if os.getlogin() != 'root':
            self.log( "You should have root permissions to execute this script.")
            sys.exit(1)
        else:
            return 0

    def logit(self, message):
        print message
        logging.info(message)

    def gmsExits(self):
        scriptInstallFile = "/var/log/datasync/script.inst"
        rpmswitch = ''
        self.slesUpgrade = 'no'
        datasync_prefix = 'datasync -'
#        ds = 'datasynchronizer'
#        imageMagick = 'Magick'

        newinstall = "yes"
        cmd = 'rpm -qa'
        p = Popen(cmd , shell=True, stdout=PIPE, stdin=PIPE, stderr=PIPE)
        for line in p.stdout:
            if 'datasync' in line:
                newinstall = "no"

        if newinstall == 'no':
            self.logit('Mobility Server is installed.  This will be an update installation.')
            gmsver = self.getgmsver()

            self.logit('Current Mobility Sever version is %s' % self.getgmsver())
        elif newinstall  == 'yes':
            self.logit('Mobility Server is not currently installed.  This will be a new installation.')

        return newinstall

    def rpmlist(self):
        #print os.getcwd()

        packages = glob('%s/suse/x86_64/*.rpm' % self.scriptDir)
        #print packages
        return packages

    def backupXml(self):
        web_server = "/etc/datasync/webadmin/server.xml"
        web_server_bak = "/etc/datasync/webadmin/server.xml.rpmsave"
        syncengine_conn = "/etc/datasync/syncengine/connectors.xml"
        syncengine_conn_bak = "/etc/datasync/syncengine/connectors.xml.rpmsave"
        syncengine_eng = "/etc/datasync/syncengine/engine.xml"
        syncengine_eng_bak = "/etc/datasync/syncengine/engine.xml.rpmsave"
        configengine_config = "/etc/datasync/configengine/configengine.xml"
        configengine_config_bak = "/etc/datasync/configengine/configengine.xml.rpmsave"
        configengine_eng = "/etc/datasync/configengine/engines/default/engine.xml"
        configengine_eng_bak = "/etc/datasync/configengine/engines/default/engine.xml.rpmsave"
        mob_ca_pem = "/var/lib/datasync/mobility/mob_ca.pem"
        mob_ca_pem_bak = "/var/lib/datasync/mobility/mob_ca.pem.rpmsave"

    def getgmsver(self):
        cmd = 'rpm -qa'
        p = Popen(cmd, shell=True, stdout=PIPE, stdin=PIPE, stderr=PIPE)
        for line in p.stdout:

            if 'datasync-webadmin' in line:
                ver = line.split('-', 2)[2]
                gmsver = '-'.join(ver.split('.')[0:3])
                return gmsver

    def promptForProperGWVersion(self):
        print 'This version of GroupWise Mobility Service requires GroupWise version 18.0.0 or above.'
#        gw18 = raw_input('Is your GroupWise System version 18.0.0 or above? (yes/no')
        sleep(1)
        gwVerAvailable= None
        while gwVerAvailable == None:

            gwVerAvailable="no"
            gwVerAvailable = raw_input("Is your GroupWise System version 18.0.0 or above? (yes/no): " ) or gwVerAvailable
            if gwVerAvailable == 'no':
                self.logit("Your GroupWise System must have a version 18.0 version or higher.")
                self.logit("Minimum requirement is for the Priamry domain to be 18.0.")
                self.logit('Exiting....')
                sys.exit(2)
        return gwVerAvailable

    def showlicense(self):
        os.system('more license.txt')

        accept = raw_input('Accept GMS EULA? (yes / no)[yes] : ')
        if accept.lower() == 'no':
            sys.exit()

        print ''

    def installpostgres(self):
        self.logit('\nInstalling Postgres Server')
        if self.slesUpgrade == 'yes':
            p = Popen(['rpm', '-qa', ' | ' , 'grep' , 'datasync'], stdout=PIPE)

            for line in p.stdout:
                print line

        else:

            cmd = ['zypper -n  in postgresql-server']
            self.popen(cmd)

    def installImageMagick(self):
        self.logit("Installing ImageMagick...")
        p = Popen('zypper -n in ImageMagick', shell=True, stdout=PIPE)
        for line in p.stdout:
            print line


    def checkImageMagick(self, imStatus):
        self.logit('Checking ImageMagick installation.')
        coreStatus = False
        wandStatus = False
        return imStatus

    def ifSlesUpgrade(self):
        web_server = "/etc/datasync/webadmin/server.xml"
        web_server_bak = "/etc/datasync/webadmin/server.xml.rpmsave"
        syncengine_conn = "/etc/datasync/syncengine/connectors.xml"
        syncengine_conn_bak = "/etc/datasync/syncengine/connectors.xml.rpmsave"
        syncengine_eng = "/etc/datasync/syncengine/engine.xml"
        syncengine_eng_bak = "/etc/datasync/syncengine/engine.xml.rpmsave"
        configengine_config = "/etc/datasync/configengine/configengine.xml"
        configengine_config_bak = "/etc/datasync/configengine/configengine.xml.rpmsave"
        configengine_eng = "/etc/datasync/configengine/engines/default/engine.xml"
        configengine_eng_bak = "/etc/datasync/configengine/engines/default/engine.xml.rpmsave"
        mob_ca_pem = "/var/lib/datasync/mobility/mob_ca.pem"
        mob_ca_pem_bak = "/var/lib/datasync/mobility/mob_ca.pem.rpmsave"



        if os.path.isfile(web_server) and os.path.isfile(web_server_bak) \
                and os.path.isfile(syncengine_conn) and os.path.isfile(syncengine_conn_bak) \
                and os.path.isfile(syncengine_eng) and os.path.isfile(syncengine_eng_bak) \
                and os.path.isfile(configengine_eng)  and os.path.isfile(configengine_eng_bak) \
                and os.path.isfile(configengine_config) and os.path.isfile(configengine_config_bak) \
                and os.path.isfile(mob_ca_pem) and os.path.isfile(mob_ca_pem_bak):
            #print "all thewre"
            return True
        else:
            return False


    def importrpmkey(self):
        # import rpm signing key
        rpmKeyFile = '%s/content.key' % self.scriptDir
        if os.path.isfile(rpmKeyFile):
            cmd = 'rpm --import %s' % rpmKeyFile
            p = Popen(cmd, shell=True, stdout=PIPE)
            for line in p.stdout:
                print line
        else:
            self.logit('RPM signing key file not found.  Can not import the key.')
            self.logit("You will get warnings when installing the RPM's, however, the RPM's will install correctly")

    def fqdn(self):
        fqdn = socket.getfqdn()
        if not fqdn:
            self.logit("There seems to be issues with the network settings.")
            self.logit("Please make sure 'hostname -f' returns a valid hostname ... exiting.")
            self.logit("There seems to be issues with the network settings. Please make sure 'hostname -f' returns a valid hostname ... exiting.")
            sys.exit(1)
        else:
            return fqdn

    def installRpmsFromdisk(self):
        rpms = self.rpmlist()
        self.logit('Installing unixODBC')
        cmd = 'zypper -n in unixODBC libodbc.so'
        odbc = self.popen(cmd)
        for line in odbc:
            print 'odbc install: %s' % line

        #cmd = 'zypper -n in libodbc.so'


        python_ldap = 'python-pyldap'
        cmd = 'zypper -n se %s' % python_ldap
        zyppersearch = self.popen(cmd)
        for line in zyppersearch:

            if 'No matching items' in line:
                print line
                python_ldap = 'python-ldap'
            elif 'python-pyldap' in line and 'package ' in line:


                cmd = 'zypper -n in %s' % python_ldap
                pythonldapinstall = self.popen(cmd)
                for line in pythonldapinstall:
                    print line


        self.logit('Installing required rpms')
        zypperlist = ['python-openssl',
                   'python-M2Crypto',
                   'python-lxml']

        rpmlist = ['python-pyodbc',
                   'librtfcomp0',
                   'psqlODBC',
                   'pycopg2',
                   'python-rtf',
                ]
        for package in zypperlist:
            cmd = 'zypper -n in %s' % package
            zypperin = self.popen(cmd)
            for line in zypperin:
                print line

        for diskrpm in rpmlist:
            print diskrpm

            for rpmname in rpms:
                #print rpmname

                if diskrpm in rpmname:
                    if diskrpm == ' librtfcomp0':
                        cmd = 'rpm -i --force %s' % rpmname
                        print 'librt command %s' % cmd
                    else:
                        cmd = 'rpm -i %s' % rpmname

                    rpmin = self.popen(cmd)
                    for line in rpmin:
                        print line

    def installPsql(self):
        cmd = 'zypper -n in postgresql-server'
        psql = self.popen(cmd)
        return psql







    def popen(self, cmd):
        p = Popen(cmd, shell=True, stdout=PIPE)
        return p.stdout