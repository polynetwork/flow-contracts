// ZeroCopySource is used to serialize bytes
pub contract ZeroCopySink {
    
    // WriteBool takes a Bool as input and returns bytes after serialize
    pub fun WriteBool(_ b: Bool): [UInt8] {
        var buff: [UInt8] = [0]
        if b {
            buff[0] = 1
        }
        return buff
    }

    // WriteByte takes a byte(UInt8) as input and returns bytes after serialize
    pub fun WriteByte(_ b: UInt8): [UInt8] {
        return [b]
    }

    // WriteUint8 takes a UInt8 as input and returns bytes after serialize
    pub fun WriteUint8(_ b: UInt8): [UInt8] {
        return [b]
    }

    // WriteUint16 takes a UInt16 as input and returns bytes after serialize
    pub fun WriteUint16(_ b: UInt16): [UInt8] {
        return [UInt8(b%256), UInt8(b/256)]
    }

    // WriteUint32 takes a UInt32 as input and returns bytes after serialize
    pub fun WriteUint32(_ b: UInt32): [UInt8] {
        let buff: [UInt8] = []
        let size = 4
        var index = 0
        var tmp = b
        while (index<size) {
            buff.append(UInt8(tmp%256))
            tmp = tmp/256
            index = index + 1
        }
        return buff
    }

    // WriteUint64 takes a UInt64 as input and returns bytes after serialize
    pub fun WriteUint64(_ b: UInt64): [UInt8] {
        let buff: [UInt8] = []
        let size = 8
        var index = 0
        var tmp = b
        while (index<size) {
            buff.append(UInt8(tmp%256))
            tmp = tmp/256
            index = index + 1
        }
        return buff
    }

    // WriteUint255 takes a UInt256 as input and returns bytes after serialize
    pub fun WriteUint255(_ b: UInt256): [UInt8] {
        let buff: [UInt8] = []
        let size = 32
        var index = 0
        var tmp = b
        while (index<size) {
            buff.append(UInt8(tmp%256))
            tmp = tmp/256
            index = index + 1
        }
        return buff
    }

    // WriteVarBytes takes bytes([UInt8]) as input and returns bytes after serialize
    pub fun WriteVarBytes(_ data: [UInt8]): [UInt8] {
        return self.WriteVarUint(UInt64(data.length)).concat(data)
    }

    // WriteVarUint takes a UInt64 as input and returns bytes after serialize
    pub fun WriteVarUint(_ v: UInt64): [UInt8] {
        if (v < 0xFD) {
            return [UInt8(v)]
        } else if (v <= 0xFFFF) {
            return [0xFD as UInt8].concat(self.WriteUint16(UInt16(v)))
    	} else if (v <= 0xFFFFFFFF) {
            return [0xFE as UInt8].concat(self.WriteUint32(UInt32(v)))
    	} else {
            return [0xFF as UInt8].concat(self.WriteUint64(UInt64(v)))
    	}
    }

}