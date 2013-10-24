#lang scribble/manual

@require[(for-label multipath-daemon)
         (for-label racket)
         (for-label unstable/socket)]

@title{Multipath Daemon API}
@author+email["Jan Dvorak" "mordae@anilinux.org"]

Library for communication with the @tt{multipathd} process via it's
UNIX domain socket.


@defmodule[multipath-daemon]

@defclass[multipath-daemon% object% ()]{
  Multipath daemon proxy operating over an abstract-namespace
  UNIX domain socket.

  @defconstructor[([path unix-socket-path? undefined])]{
    Create proxy, optionally using a non-default socket path.
  }

  @defmethod[(reconfigure) boolean?]{
    Ask @tt{multipathd} to re-read it's configuration file and reconfigure
    all multipath maps.  Basically equivalent to restarting it.
  }

  @defmethod[(list-paths) (listof (hash/c symbol? any/c))]{
    Queries known device paths.

    Every path looks approximately like this:

    @racketblock['#hasheq((device . "sda")
                          (major . 8)
                          (minor . 0)
                          (status . running)
                          (uuid . "foobar-3cc708a235e4c035"))]
  }

  @defmethod[(list-maps) (hash/c symbol? any/c)]{
    Queries known multipath maps (virtual devices diverting I/O to
    individual paths).

    Every such map looks approximately like this:

    @racketblock['#hasheq((device . "disk1")
                          (name . "disk1")
                          (uuid . "foobar-3cc708a235e4c035"))]
  }
}


@; vim:set ft=scribble sw=2 ts=2 et:
