#!/usr/bin/python

import os, sys, logging, rpm, socket
from subprocess import Popen, PIPE
import install_lib  as gmslib
from time import sleep


def loggingSetup():
    logpath = '/var/log/datasync'
    if not os.path.exists(logpath):
        os.makedirs(logpath)
    logfile = '/%s/install.log' % logpath
    if not os.path.isfile(logfile):
        open(logfile, 'a').close()
    logging.basicConfig(level=logging.INFO,
                        format='%(asctime)s %(message)s',
                        datefmt='%H:%M',
                        filename=logfile,
                        filemode='w')


def main():
    gms.logit('Welcome to the Micro Focus GroupWise Mobility Service install.')
    gms.whoami()
    newinstall = gms.gmsExits()
    # print 'new = %s' % newinstall
    gms.logit('slesUpgrade = %s' % gms.ifSlesUpgrade())
    scriptInstallFile = "/var/log/datasync/script.inst"
    rpmswitch = ''
    if os.path.isfile(scriptInstallFile):
        rpmswitch = '--replacefiles'
    slesUpgrage = False
    importkey = gms.importrpmkey()
    gms.showlicense()

    gms.logit('Starting GMS installation.')

    #check if the network setting are correctly configured
    fqdn = gms.fqdn()
    gms.logit('Server Hostname : %s' % fqdn)

    gw18 = gms.promptForProperGWVersion()
    #gw18 = 'yes'
    if gw18 == 'no':
        sys.exit()

    #get rpm info
    rpms = gms.getrpminfo()

    #install postgres
    pginstall = gms.installpostgres()



    # install ImageMagick
    for key, value in rpms.iteritems():
        if key == 'ImageMagick':
            imInstall = True
        else:
            imInstall = False

#    print imInstall
    gms.installImageMagick()
    #checkIm = gms.checkImageMagick(imInstall)
    sleep(2)

#install unixODBC
    odbcinstall = gms.installUnixODBC()
    #print odbcinstall
    sleep(2)
# install pythoh-ldap
    ldapinstall = gms.installLdap()
    sleep(2)

 #   gmsrpms = gms.rpmlist()
    rpminstall = gms.installRpmsFromdisk()





if __name__ == '__main__':
    loggingSetup()
    gms = gmslib.GMSINSTALL()
    main()

