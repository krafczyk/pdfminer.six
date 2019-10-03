import six
from libc.stdlib cimport malloc, free
from cpython.bytes cimport PyBytes_FromStringAndSize

##  PNG Predictor
##
def apply_png_predictor(pred, colors, columns, bitspercomponent, data):
    if bitspercomponent != 8:
        # unsupported
        raise ValueError("Unsupported `bitspercomponent': %d" %
                         bitspercomponent)
    nbytes = colors * columns * bitspercomponent // 8
    i = 0
    buf = b''
    line0 = b'\x00' * columns
    for i in range(0, len(data), nbytes+1):
        ft = data[i]
        if six.PY2:
            ft = six.byte2int(ft)
        i += 1
        line1 = data[i:i+nbytes]
        line2 = b''
        if ft == 0:
            # PNG none
            line2 += line1
        elif ft == 1:
            # PNG sub (UNTESTED)
            c = 0
            for b in line1:
                if six.PY2:
                    b = six.byte2int(b)
                c = (c+b) & 255
                line2 += six.int2byte(c)
        elif ft == 2:
            # PNG up
            for (a, b) in zip(line0, line1):
                if six.PY2:
                    a, b = six.byte2int(a), six.byte2int(b)
                c = (a+b) & 255
                line2 += six.int2byte(c)
        elif ft == 3:
            # PNG average (UNTESTED)
            c = 0
            for (a, b) in zip(line0, line1):
                if six.PY2:
                    a, b = six.byte2int(a), six.byte2int(b)
                c = ((c+a+b)//2) & 255
                line2 += six.int2byte(c)
        else:
            # unsupported
            raise ValueError("Unsupported predictor value: %d" % ft)
        buf += line2
        line0 = line2
    return buf

def apply_png_predictor_py3(pred, colors, columns, bitspercomponent, const unsigned char[:] data):
    if bitspercomponent != 8:
        # unsupported
        raise ValueError("Unsupported `bitspercomponent': %d" %
                         bitspercomponent)
    cdef int nbytes = colors * columns * bitspercomponent // 8
    cdef int cols = columns
    cdef int i = 0
    cdef int ii = 0
    cdef int I = 0
    cdef int j = 0
    cdef int c = 0
    cdef int length = data.shape[0]
    cdef int scanlines = length // (nbytes+1)
    cdef unsigned char* buff = <unsigned char*> malloc(scanlines*nbytes)
    cdef unsigned char* line0 = <unsigned char*> malloc(cols)
    cdef unsigned char ft
    # Initialize line0
    for i in range(cols):
        line0[i] = 0
    for I in range(scanlines):
        i = I*(nbytes+1)
        ii = I*nbytes
        ft = data[i]
        i += 1
        if ft == 0:
            # PNG none
            for j in range(nbytes):
                buff[ii+j] = data[i+j]
        elif ft == 1:
            # PNG sub (UNTESTED)
            c = 0
            for j in range(nbytes):
                c = (c+data[i+j]) & 255
                buff[ii+j] = c
        elif ft == 2:
            # PNG up
            for j in range(nbytes):
                c = (line0[j]+data[i+j]) & 255
                buff[ii+j] = c
        elif ft == 3:
            # PNG average (UNTESTED)
            c = 0
            for j in range(nbytes):
                c = ((c+line0[j]+data[i+j])//2) & 255
                buff[ii+j] = c
        else:
            # unsupported
            free(buff)
            free(line0)
            raise ValueError("Unsupported predictor value: %d" % ft)
        # Copy recently written line to use in next round
        for j in range(nbytes):
            line0[j] = buff[ii+j]
    # Get bytes object from the buffer.
    # This is necessary because otherwise buff is treated as a null terminated string.
    answer = PyBytes_FromStringAndSize(<char*> buff, scanlines*nbytes)
    free(buff)
    free(line0)
    return answer
