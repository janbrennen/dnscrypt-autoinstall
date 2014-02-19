#! /bin/sh
### BEGIN INIT INFO
# Provides:          dnscrypt-proxy
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: dnscrypt-proxy
# Description:       dnscrypt-proxy secure DNS client
### END INIT INFO

# Author: Simon Clausen <kontakt@simonclausen.dk> 
# Additional edits by: Jan Brennen https://github.com/janbrennen

PATH=/usr/sbin:/usr/bin:/sbin:/bin
DAEMON=/usr/local/sbin/dnscrypt-proxy
NAME=dnscrypt-proxy
ADDRESS1=185.19.104.45
ADDRESS2=185.19.105.6
PNAME1=2.dnscrypt-cert.ns8.uk.dns.opennic.glue
PNAME2=2.dnscrypt-cert.ns9.uk.dns.opennic.glue
PKEY=A17C:06FC:BA21:F2AC:F4CD:9374:016A:684F:4F56:564A:EB30:A422:3D9D:1580:A461:B6A6
PKEY=E864:80D9:DFBD:9DB4:58EA:8063:292F:EC41:9126:8394:BC44:FAB8:4B6E:B104:8C3B:E0B4

PIDFILE1=/var/run/$NAME-1.pid
PIDFILE2=/var/run/$NAME-2.pid
USER=dnscrypt
DESC="Secure DNS Proxy"
DAEMON_OPTS="--daemonize --user=dnscrypt --local-address=127.0.0.1 --resolver-address=$ADDRESS1 --provider-name=$PNAME1 --provider-key=$PKEY1"
DAEMON_OPTS2="--daemonize --user=dnscrypt --local-address=127.0.0.2 --resolver-address=$ADDRESS2 --provider-name=$PNAME2 --provider-key=$PKEY2"

test -x $DAEMON || exit 0
. /lib/lsb/init-functions

case "$1" in
  start)
    log_daemon_msg "Starting $DESC" $NAME
    start-stop-daemon --start --quiet --pidfile $PIDFILE1 --background --exec\
      $DAEMON -- $DAEMON_OPTS --pidfile=$PIDFILE1
    RET1=$?
    start-stop-daemon --start --quiet --pidfile $PIDFILE2 --background --exec\
      $DAEMON -- $DAEMON_OPTS2 --pidfile=$PIDFILE2
    RET2=$?
    RET=$((RET1+RET2))
    log_end_msg $RET
    ;;
  stop)
    log_daemon_msg "Stopping $DESC" $NAME
    start-stop-daemon --stop --quiet --pidfile $PIDFILE1 \
        --exec $DAEMON
    RET1=$?
    start-stop-daemon --stop --quiet --pidfile $PIDFILE2 \
        --exec $DAEMON
    RET2=$?
    RET=$((RET1+RET2))
    rm -f $PIDFILE1 $PIDFILE2
    log_end_msg $RET
    ;;
  restart|force-reload)
    sh $0 stop
    sleep 1
    sh $0 start
    ;;
  status)
    status_of_proc "$DAEMON" "$NAME" && exit 0 || exit $?
    ;;
  *)
    echo "Usage: /etc/init.d/$NAME {start|stop|restart}" >&2
    exit 1
    ;;
esac

exit 0
