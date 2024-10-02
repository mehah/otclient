Bit = {}

function Bit.bit(p)
    return 2 ^ p
end

function Bit.hasBit(x, p)
    return x % (p + p) >= p
end

function Bit.setbit(x, p)
    return Bit.hasBit(x, p) and x or x + p
end

function Bit.clearbit(x, p)
    return Bit.hasBit(x, p) and x - p or x
end

Bit.OR = 1
Bit.XOR = 3
Bit.AND = 4

function Bit.operation(a, b, oper)
   local r, m, s = 0, 2^31
   repeat
      s,a,b = a+b+m, a%m, b%m
      r,m = r + m*oper%(s-a-b), m/2
   until m < 1
   return r
end