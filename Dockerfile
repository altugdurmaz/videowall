FROM balenalib/raspberrypi3-debian-python:2-stretch-build

WORKDIR /usr/app/videowall
COPY . .
RUN pip install -r requirements.txt --extra-index-url=https://www.piwheels.org/simple

RUN install_packages \
        autotools-dev \
        automake \
        libtool \
        libraspberrypi0 \
        libraspberrypi-dev \
        libraspberrypi-bin \
        gstreamer1.0-x \
        gstreamer1.0-plugins-base \
        libgstreamer-plugins-base1.0-dev \
        gstreamer1.0-plugins-base-apps \
        gstreamer1.0-tools \
        gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-bad \
        libmediainfo-dev \
        python-gi \
        rsync \
        cmake

RUN git clone https://github.com/reinzor/gst-mmal /tmp/gst-mmal
WORKDIR /tmp/gst-mmal
ENV LDFLAGS='-L/opt/vc/lib'
ENV CPPFLAGS='-I/opt/vc/include -I/opt/vc/include/interface/vcos/pthreads -I/opt/vc/include/interface/vmcs_host/linux'
RUN ./autogen.sh --disable-gtk-doc
RUN make && make install


RUN git clone https://github.com/reinzor/gst-omx /tmp/gst-omx
WORKDIR /tmp/gst-omx
RUN git checkout 1.10.4
ENV CFLAGS='-I/opt/vc/include -I/opt/vc/include/IL -I/opt/vc/include/interface/vcos/pthreads -I/opt/vc/include/interface/vmcs_host/linux -I/opt/vc/include/IL' CPPFLAGS='-I/opt/vc/include -I/opt/vc/include/IL -I/opt/vc/include/interface/vcos/pthreads -I/opt/vc/include/interface/vmcs_host/linux -I/opt/vc/include/IL'
RUN ./autogen.sh --disable-gtk-doc --with-omx-target=rpi
RUN make && make install


# ENV PYTHONPATH='"$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"/src'
ENV PYTHONPATH='/usr/lib/python2.7/dist-packages:/usr/lib/python2.7/site-packages:/usr/app/videowall/src'
ENV GST_DEBUG='1'
ENV GST_PLUGIN_PATH='/usr/local/lib/gstreamer-1.0:/usr/lib/arm-linux-gnueabihf/gstreamer-1.0'
ENV LC_ALL=C

RUN ln -s /usr/lib/python2.7/dist-packages/gi/_gi.arm-linux-gnueabihf.so /usr/lib/python2.7/dist-packages/gi/_gi.so

WORKDIR /usr/src/fbcp
RUN curl -sSL https://raw.githubusercontent.com/tasanakorn/rpi-fbcp/master/CMakeLists.txt -O
RUN curl -sSL https://raw.githubusercontent.com/tasanakorn/rpi-fbcp/master/main.c -O
WORKDIR /usr/src/fbcp/build
RUN cmake .. && make


WORKDIR /usr/app/videowall
COPY entry.sh .
COPY SteamedHams.mp4 ./videos/
# CMD ["/scripts/client","rpi","eth0"]
# CMD while : ; do echo "${MESSAGE=Idling...}"; sleep ${INTERVAL=600}; done
CMD ["./entry.sh"]