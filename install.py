#!/usr/bin/python

import os, sys, logging, rpm, socket
from subprocess import Popen, PIPE
import install_lib  as gmslib



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
    scriptInstallFile = "/var/log/datasync/script.inst"
    rpmswitch = ''
    if os.path.isfile(scriptInstallFile):
        rpmswitch = '--replacefiles'
    slesUpgrage = False
    #gms.showlicense()
    gms.whoami()
    #
    #newinstall= gms.gmsExits()
    #print 'new = %s' % newinstall
    #print 'slesUpgrade = %s' % gms.ifSlesUpgrade()

    #print gmsrpms

    #for key, value in rpms.iteritems():
    #    print key
    #    print value

    #gms.installpostgres()

    rpms = gms.getrpminfo()
    for key, value in rpms.iteritems():
        if key == 'ImageMagick':
            imInstall = True
            instIm = gms.installImageMagick()
        else:
            imInstall = False




#    print imInstall
    #gms.installImageMagick()
    checkIm = gms.checkImageMagick(imInstall)

    #import rpm signing key

    importkey = gms.importrpmkey()

    ##check if the network setting are correctly configured
    fqdn = gms.fqdn()
    print fqdn
    #gw18 = gms.promptForProperGWVersion()
    gw18 = 'yes'
    if gw18 == 'no':
        sys.exit()

    sqlinstall = gms.installPsql()
    for line in sqlinstall:
        print line

    gmsrpms = gms.rpmlist()

    rpminstall = gms.installRpmsFromdisk()





if __name__ == '__main__':
    loggingSetup()
    gms = gmslib.GMSINSTALL()
    main()