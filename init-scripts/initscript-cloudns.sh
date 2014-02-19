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
ADDRESS1=113.20.6.2
ADDRESS2=113.20.8.17
PNAME1=2.dnscrypt-cert.cloudns.com.au
PNAME2=2.dnscrypt-cert-2.cloudns.com.au
PKEY1=1971:7C1A:C550:6C09:F09B:ACB1:1AF7:C349:6425:2676:247F:B738:1C5A:243A:C1CC:89F4
PKEY2=67A4:323E:581F:79B9:BC54:825F:54FE:1025:8B4F:37EB:0D07:0BCE:4010:6195:D94F:E330


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
