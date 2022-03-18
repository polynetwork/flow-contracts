// ZeroCopySource is used to deserialize bytes
pub contract ZeroCopySource {
    
    // ZeroCopySourceResult contain the decoded result
    /* Fields:
        res: the decoded result
        offset: offset of next parameter in the bytes stream
    */
    pub struct ZeroCopySourceResult {
        pub(set) var res: AnyStruct
        pub(set) var offset: UInt256
        init (_res: AnyStruct, _offset: UInt256) {
            self.res = _res
            self.offset = _offset
        }
    }
    
    // NextBool parses the data at the specified offset of buff as a boolean
    pub fun NextBool(buff: [UInt8], offset: UInt256): ZeroCopySourceResult {
        pre {
            offset + 1 <= UInt256(buff.length): "NextBool, Offset exceeds maximum"
        }
        if (buff[offset]==0) {
            return ZeroCopySourceResult(_res: false as Bool, _offset: offset+1)
        } else if (buff[offset]==1) {
            return ZeroCopySourceResult(_res: true as Bool, _offset: offset+1)
        } else {
            panic("NextBool value error")
        }
        return ZeroCopySourceResult(_res: nil,_offset: offset+1)
    }

    // NextByte parses the data at the specified offset of buff as a byte(UInt8)
    pub fun NextByte(buff: [UInt8], offset: UInt256): ZeroCopySourceResult {
        pre {
            offset + 1 <= UInt256(buff.length): "NextByte, Offset exceeds maximum"
        }
        return ZeroCopySourceResult(_res: buff[offset],_offset: offset+1)
    }

    // NextUint8 parses the data at the specified offset of buff as a UInt8
    pub fun NextUint8(buff: [UInt8], offset: UInt256): ZeroCopySourceResult {
        pre {
            offset + 1 <= UInt256(buff.length): "NextUint8, Offset exceeds maximum"
        }
        return ZeroCopySourceResult(_res: buff[offset],_offset: offset+1)
    }

    // NextUint16 parses the data at the specified offset of buff as a UInt16
    pub fun NextUint16(buff: [UInt8], offset: UInt256): ZeroCopySourceResult {
        pre {
            offset + 2 <= UInt256(buff.length): "NextUint16, Offset exceeds maximum"
        }
        var res: UInt16 = UInt16(buff[offset]) + UInt16(buff[offset+1])*256
        return ZeroCopySourceResult(_res: res as UInt16, _offset: offset+2)
    }

    // NextUint32 parses the data at the specified offset of buff as a UInt32
    pub fun NextUint32(buff: [UInt8], offset: UInt256): ZeroCopySourceResult {
        pre {
            offset + 4 <= UInt256(buff.length): "NextUint32, Offset exceeds maximum"
        }
        let size: UInt256 = 4
        var index: UInt256 = 0
        var res: UInt32 = 0
        while (index<size) {
            res = res + UInt32(buff[index+offset]) * (0x1 << UInt32(index*8))
            index = index + 1
        }
        return ZeroCopySourceResult(_res: res as UInt32, _offset: offset+4)
    }

    // NextUint64 parses the data at the specified offset of buff as a UInt64
    pub fun NextUint64(buff: [UInt8], offset: UInt256): ZeroCopySourceResult {
        pre {
            offset + 8 <= UInt256(buff.length): "NextUint64, Offset exceeds maximum"
        }
        let size: UInt256 = 8
        var index: UInt256 = 0
        var res: UInt64 = 0
        while (index<size) {
            res = res + UInt64(buff[index+offset]) * (0x1 << UInt64(index*8))
            index = index + 1
        }
        return ZeroCopySourceResult(_res: res as UInt64, _offset: offset+8)
    }

    // NextUint255 parses the data at the specified offset of buff as a UInt256
    pub fun NextUint255(buff: [UInt8], offset: UInt256): ZeroCopySourceResult {
        pre {
            offset + 32 <= UInt256(buff.length): "NextUint255, Offset exceeds maximum"
        }
        let size: UInt256 = 32
        var index: UInt256 = 0
        var res: UInt256 = 0
        while (index<size) {
            res = res + UInt256(buff[index+offset]) * (0x1 << UInt256(index*8))
            index = index + 1
        }
        return ZeroCopySourceResult(_res: res as UInt256, _offset: offset+32)
    }

    // NextVarBytes parses the data at the specified offset of buff as Bytes([UInt8])
    pub fun NextVarBytes(buff: [UInt8], offset: UInt256): ZeroCopySourceResult {
        var tmp: ZeroCopySourceResult = self.NextVarUint(buff: buff, offset: offset)
        var len: UInt256 = (tmp.res as? UInt256)!
        var _offset: UInt256 = tmp.offset
        assert(_offset + len <= UInt256(buff.length), message: "NextVarBytes, Offset exceeds maximum")
        var res: [UInt8] = []
        var index = 0 as UInt256
        while (index<len) {
            res.append(buff[_offset+index])
            index = index + 1
        }
        return ZeroCopySourceResult(_res: res as [UInt8], _offset: _offset+len)
    }

    // NextHash parses the data at the specified offset of buff as Hash([UInt8])
    pub fun NextHash(buff: [UInt8], offset: UInt256): ZeroCopySourceResult {
        var len: UInt256 = 32
        assert(offset + len <= UInt256(buff.length), message: "NextHash, Offset exceeds maximum")
        var res: [UInt8] = []
        var index = 0 as UInt256
        while (index<len) {
            res.append(buff[offset+index])
            index = index + 1
        }
        return ZeroCopySourceResult(_res: res as [UInt8], _offset: offset+len)
    }

    // NextBytes20 parses the data at the specified offset of buff as Bytes32([UInt8])
    pub fun NextBytes20(buff: [UInt8], offset: UInt256): ZeroCopySourceResult {
        var len: UInt256 = 20
        assert(offset + len <= UInt256(buff.length), message: "NextBytes20, Offset exceeds maximum")
        var res: [UInt8] = []
        var index = 0 as UInt256
        while (index<len) {
            res.append(buff[offset+index])
            index = index + 1
        }
        return ZeroCopySourceResult(_res: res as [UInt8], _offset: offset+len)
    }

    // NextVarUint parses the data at the specified offset of buff as UInt (returns as UInt256)
    pub fun NextVarUint(buff: [UInt8], offset: UInt256): ZeroCopySourceResult {
        assert(offset + 1 <= UInt256(buff.length), message: "NextVarUint, Offset exceeds maximum")
        var v: UInt8 = buff[offset]
        var res: ZeroCopySourceResult = ZeroCopySourceResult(_res: nil, _offset: offset+32)
        if (v < 0xFD) {
            res = ZeroCopySourceResult(_res: UInt256(v) as UInt256, _offset: offset+1)
        } else if (v == 0xFD) {
            res = self.NextUint16(buff: buff, offset: offset + 1)
            assert((res.res as? UInt16)! >= 0xFD, message: "NextVarUint, UInt16 value outside range")
            res.res = UInt256((res.res as? UInt16)!)
        } else if (v == 0xFE) {
            res = self.NextUint32(buff: buff, offset: offset + 1)
            assert((res.res as? UInt32)! >= 0xFFFF, message: "NextVarUint, UInt32 value outside range")
            res.res = UInt256((res.res as? UInt32)!)
        } else if (v == 0xFF) {
            res = self.NextUint64(buff: buff, offset: offset + 1)
            assert((res.res as? UInt64)! >= 0xFFFFFFFF, message: "NextVarUint, UInt64 value outside range")
            res.res = UInt256((res.res as? UInt64)!)
        } else {
            panic("NextVarUint, value outside range")
        }
        return res
    }
}