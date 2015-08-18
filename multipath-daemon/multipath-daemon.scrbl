#lang scribble/manual

@require[(for-label multipath-daemon)
         (for-label racket)
         (for-label racket/unix-socket)]

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

  @defmethod[(reconfigure) boolean?]{
    Ask @tt{multipathd} to re-read it's configuration file and reconfigure
    all multipath maps.  Basically equivalent to restarting it.
  }

  @defmethod[(add-path [name string?]) void?]{
    Add path by @tt{name} or @tt{uuid}.
  }

  @defmethod[(remove-path [name string?]) void?]{
    Remove path by @tt{name} or @tt{uuid}.
  }

  @defmethod[(add-map [name string?]) void?]{
    Add multipath mapping by @tt{name} or @tt{uuid}.
  }

  @defmethod[(remove-map [name string?]) void?]{
    Remove multipath mapping by @tt{name} or @tt{uuid}.
  }

  @defmethod[(suspend-map [name string?]) void?]{
    Suspend multipath mapping by @tt{name} or @tt{uuid}.
    Suspended maps block on all access and can be safely redefined.
  }

  @defmethod[(resume-map [name string?]) void?]{
    Resume previously suspended multipath map.
  }

  @defmethod[(resize-map [name string?]) void?]{
    Ask the daemon to re-detect size of mapping paths and resize the
    mapping accordingly.
  }

  @defmethod[(reset-map [name string?]) void?]{
    Reset multipath mapping by @tt{name} or @tt{uuid}.
  }

  @defmethod[(reload-map [name string?]) void?]{
    Reload multipath mapping by @tt{name} or @tt{uuid}.
  }

  @defmethod[(fail-path [name string?]) void?]{
    Mark path as failed.
  }

  @defmethod[(reinstate-path [name string?]) void?]{
    Mark path as accessible again.
  }

  @defmethod[(disable-map-queuing [name string?]) void?]{
    Disable queuing on a single mapping.
  }

  @defmethod[(disable-queuing) void?]{
    Disable queuing globally.
  }

  @defmethod[(restore-map-queuing [name string?]) void?]{
    Restore queuing on a single mapping.
  }

  @defmethod[(restore-queuing) void?]{
    Restore queuing globally.
  }
}


@; vim:set ft=scribble sw=2 ts=2 et:
