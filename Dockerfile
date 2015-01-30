FROM progrium/busybox

RUN mkdir /build
ADD src /build
RUN /build/install.sh
