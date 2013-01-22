#
# Color
# A collection of utilities for handling color.
#

export Color, color, ColorOrNothing, ColorStringOrNothing,
       Colour, colour, ColourOrNothing, ColourStringOrNothing,
       weighted_color_mean,
       RGB, HLS, XYZ, LAB, LUV, LCHab, LCHuv

abstract Color
typealias ColorOrNothing Union(Color, String, Nothing)
typealias ColorOrStringOrNothing Union(Color, String, Nothing)


# For our non-american pals.
typealias Colour Color
typealias ColourOrNothing ColorOrNothing
typealias ColourOrStringOrNothing ColorOrNothing


# sRGB (standard Red-Green-Blue)
type RGB <: Color
    r::Float64 # Red in [0,1]
    g::Float64 # Green in [0,1]
    b::Float64 # Blue in [0,1]

    function RGB(r::Number, g::Number, b::Number)
        new(r, g, b)
    end

    RGB() = RGB(0, 0, 0)
end


# HSV (Hue-Saturation-Value)
type HSV <: Color
    h::Float64 # Hue in [0,360]
    s::Float64 # Saturation in [0,1]
    v::Float64 # Value in [0,1]

    function HSV(h::Number, s::Number, v::Number)
        new(h, s, n)
    end

    HSV() = HSV(0, 0, 0)
end

# HLS (Hue-Lightness-Saturation)
type HLS <: Color
    h::Float64 # Hue in [0,360]
    l::Float64 # Lightness in [0,1]
    s::Float64 # Saturation in [0,1]

    function HLS(h::Number, l::Number, s::Number)
        new(h, l, s)
    end

    HLS() = HLS(0, 0, 0)
end

# XYZ (CIE 1931)
type XYZ <: Color
    x::Float64
    y::Float64
    z::Float64

    function XYZ(x::Number, y::Number, z::Number)
        new(x, y, z)
    end

    XYZ() = XYZ(0, 0, 0)
end

# LAB (CIELAB)
type LAB <: Color
    l::Float64 # Luminance in [0,1]
    a::Float64 # Red/Green in [-1,1]
    b::Float64 # Blue/Yellow in [-1,1]

    function LAB(l::Number, a::Number, b::Number)
        new(l, a, b)
    end

    LAB() = LAB(0, 0, 0)
end

# LCHab (Luminance-Chroma-Hue, Polar-LAB)
type LCHab <: Color
    l::Float64 # Luminance
    c::Float64 # Chroma
    h::Float64 # Hue

    function LCHab(l::Number, c::Number, h::Number)
        new(l, c, h)
    end

    LCHab() = LCHab(0, 0, 0)
end

# LUV (CIELUV)
type LUV <: Color
    l::Float64 # Luminance in [0,1]
    u::Float64 # Red/Green in [-1,1]
    v::Float64 # Blue/Yellow in [-1,1]

    function LUV(l::Number, u::Number, v::Number)
        new(l, u, v)
    end

    LUV() = LUV(0, 0, 0)
end

# LCHuv (Luminance-Chroma-Hue, Polar-LUV)
type LCHuv <: Color
    l::Float64 # Luminance
    c::Float64 # Chroma
    h::Float64 # Hue

    function LCHuv(l::Number, c::Number, h::Number)
        new(l, c, h)
    end

    LCHuv() = LCHuv(0, 0, 0)
end


# Arbitrary ordering
# ------------------

isless(a::RGB, b::RGB) = (a.r, a.g, a.b) < (b.r, b.g, b.b)
isless(a::Color, b::Color) = convert(RGB, a) < convert(RGB, b)


# White-points
# ------------

const WP_A   = XYZ(1.09850, 1.00000, 0.35585)
const WP_B   = XYZ(0.99072, 1.00000, 0.85223)
const WP_C   = XYZ(0.98074, 1.00000, 1.18232)
const WP_D50 = XYZ(0.96422, 1.00000, 0.82521)
const WP_D55 = XYZ(0.95682, 1.00000, 0.92149)
const WP_D65 = XYZ(0.95047, 1.00000, 1.08883)
const WP_D75 = XYZ(0.94972, 1.00000, 1.22638)
const WP_E   = XYZ(1.00000, 1.00000, 1.00000)
const WP_F2  = XYZ(0.99186, 1.00000, 0.67393)
const WP_F7  = XYZ(0.95041, 1.00000, 1.08747)
const WP_F11 = XYZ(1.00962, 1.00000, 0.64350)
const WP_DEFAULT = WP_D65


# Chromatic Adaptation
# --------------------

# This is the Sharp cromatic adaptation method, which is purported to be
# slightly better than the Bradford method. (TODO: cite)
const chrom_adapt_sharp =
    [1.2694 -0.0988 -0.1706
    -0.8364  1.8006  0.0357
     0.0297 -0.0315  1.0018]


function chrom_adapt(c::XYZ, src_wp::XYZ, dest_wp::XYZ)
    z = [dest_wp.x dest_wp.y dest_wp.z] ./ [src_wp.x src_wp.y src_wp.z]
    ans = (inv(chrom_adapt_sharp) * diagm(z) * chrom_adapt_sharp) * [c.x, c.y, c.z]
    XYZ(ans[1], ans[2], ans[3])
end



# Utilities
# ---------

# Linear-interpolation in [a, b] where x is in [0,1],
# or coerced to be if not.
function lerp(x::Float64, a::Float64, b::Float64)
    a + (b - a) * max(min(x, 1.0), 0.0)
end




# RGB Functions
# -------------
function hex(c::RGB)
    @sprintf("#%02X%02X%02X",
             int(lerp(c.r, 0.0, 255.0)),
             int(lerp(c.g, 0.0, 255.0)),
             int(lerp(c.b, 0.0, 255.0)))
end

hex(c::Color) = hex(convert(RGB, c))


# Everything to RGB
# -----------------

function convert(::Type{RGB}, c::HSV)
    h = c.h / 60
    i = floor(h)
    f = h - i
    if int(i) & 1 == 0
        f = 1 - f
    end
    m = c.v * (1 - c.s)
    n = c.v * (1 - c.s * f)
    i = int(i)
    if i == 6 || i == 0; RGB(c.v, n, m)
    elseif i == 1;       RGB(n, c.v, m)
    elseif i == 2;       RGB(m, c.v, n)
    elseif i == 3;       RGB(m, n, c.v)
    elseif i == 4;       RGB(n, m, c.v)
    else;                RGB(c.v, m, n)
    end
end

function convert(::Type{RGB}, c::HLS)
    function qtrans(u::Float64, v::Float64, hue::Float64)
        if     hue > 360; hue -= 360
        elseif hue < 0;   hue += 360
        end

        if     hue < 60;  u + (v - u) * hue / 60
        elseif hue < 180; v
        elseif hue < 240; u + (v - u) * (240 - hue) / 60
        else;             u
        end
    end

    v = c.l <= 0.5 ? c.l * (1 + c.s) : c.l + c.s - (c.l * c.s)
    u = 2 * c.l - v

    if c.s == 0; RGB(c.l, c.l, c.l)
    else;        RGB(qtrans(u, v, c.h + 120),
                     qtrans(u, v, c.h),
                     qtrans(u, v, c.h - 120))
    end
end

const M_XYZ_RGB = [ 3.2404542 -1.5371385 -0.4985314
                   -0.9692660  1.8760108  0.0415560
                    0.0556434 -0.2040259  1.0572252 ]


function correct_gamut(c::RGB)
    c.r = min(1.0, max(0.0, c.r))
    c.g = min(1.0, max(0.0, c.g))
    c.b = min(1.0, max(0.0, c.b))
    c
end

function srgb_compand(v::Float64)
    v <= 0.0031308 ? 12.92v : 1.055v^(1/2.4) - 0.055
end

function convert(::Type{RGB}, c::XYZ)
    ans = M_XYZ_RGB * [c.x, c.y, c.z]
    correct_gamut(RGB(srgb_compand(ans[1]),
                      srgb_compand(ans[2]),
                      srgb_compand(ans[3])))
end

convert(::Type{RGB}, c::LAB)   = convert(RGB, convert(XYZ, c))
convert(::Type{RGB}, c::LCHab) = convert(RGB, convert(LAB, c))
convert(::Type{RGB}, c::LUV)   = convert(RGB, convert(XYZ, c))
convert(::Type{RGB}, c::LCHuv) = convert(RGB, convert(LUV, c))


# Everything to HSV
# -----------------

function convert(::Type{HSV}, c::RGB)
    c_min = min([c.r, c.g, c.b])
    c_max = max([c.r, c.g, c.b])
    if c_min == c_max
        return HSV(0.0, 0.0, c_max)
    end

    if c_min == c.r
        f = c.g - c.b
        i = 3.
    elseif c_min == c.g
        f = c.b - c.r
        i = 5.
    else
        f = c.r - c.g
        i = 1.
    end

    HSV(60 * (i - f / (c_max - c_min)),
        (c_max - c_min) / c_max,
        c_max)
end

convert(::Type{HSV}, c::HLS) =   convert(HSV, convert(RGB, c))
convert(::Type{HSV}, c::XYZ)   = convert(HSV, convert(RGB, c))
convert(::Type{HSV}, c::LAB)   = convert(HSV, convert(RGB, c))
convert(::Type{HSV}, c::LCHab) = convert(HSV, convert(RGB, c))
convert(::Type{HSV}, c::LUV)   = convert(HSV, convert(RGB, c))
convert(::Type{HSV}, c::LCHuv) = convert(HSV, convert(RGB, c))


# Everything to HLS
# -----------------

function convert(::Type{HLS}, c::RGB)
    c_min = min([c.r, c.g, c.b])
    c_max = max([c.r, c.g, c.b])
    l = (c_max - c_min) / 2

    if c_max == c_min
        return HLS(0.0, l, 0.0)
    end

    if l < 0.5; s = (c_max - c_min) / (c_max + c_min)
    else;       s = (c_max - c_min) / (2.0 - c_max - c_min)
    end

    if c_max == c.r
        h = (c.g - c.b) / (c_max - c_min)
    elseif c_max == c.g
        h = 2.0 + (c.b - c.r) / (c_max - c_min)
    else
        h = 4.0 + (c.r - c.g) / (c_max - c_min)
    end

    h *= 60
    if h < 0
        h += 360
    elseif h > 360
        h -= 360
    end

    HLS(h,l,s)
end

convert(::Type{HLS}, c::HLS)   = convert(HLS, convert(RGB, c))
convert(::Type{HLS}, c::XYZ)   = convert(HLS, convert(RGB, c))
convert(::Type{HLS}, c::LAB)   = convert(HLS, convert(RGB, c))
convert(::Type{HLS}, c::LCHab) = convert(HLS, convert(RGB, c))
convert(::Type{HLS}, c::LUV)   = convert(HLS, convert(RGB, c))
convert(::Type{HLS}, c::LCHuv) = convert(HLS, convert(RGB, c))


# Everything to XYZ
# -----------------

function invert_rgb_compand(v::Float64)
    v <= 0.04045 ? v/12.92 : ((v+0.055) /1.055)^2.4
end

const M_RGB_XYZ =
    [ 0.4124564  0.3575761  0.1804375
      0.2126729  0.7151522  0.0721750
      0.0193339  0.1191920  0.9503041 ]

function convert(::Type{XYZ}, c::RGB)
    v = [invert_rgb_compand(c.r),
         invert_rgb_compand(c.g),
         invert_rgb_compand(c.b)]
    ans = M_RGB_XYZ * v
    XYZ(ans[1], ans[2], ans[3])
end

convert(::Type{XYZ}, c::HSV) = convert(XYZ, convert(RGB, c))
convert(::Type{XYZ}, c::HLS) = convert(XYZ, convert(RGB, c))

const xyz_epsilon = 216. / 24389.
const xyz_kappa   = 24389. / 27.

function convert(::Type{XYZ}, c::LAB, wp::XYZ)
    fy = (c.l + 16) / 116
    fx = c.a / 500 + fy
    fz = fy - c.b / 200

    fx3 = fx^3
    fz3 = fz^3

    x = fx3 > xyz_epsilon ? fx3 : (116fx - 16) / xyz_kappa
    y = c.l > xyz_kappa * xyz_epsilon ? ((c. l+ 16) / 116)^3 : c.l / xyz_kappa
    z = fz3 > xyz_epsilon ? fz3 : (116fz - 16) / xyz_kappa

    XYZ(x*wp.x, y*wp.y, z*wp.z)
end

convert(::Type{XYZ}, c::LAB)   = convert(XYZ, c, WP_DEFAULT)
convert(::Type{XYZ}, c::LCHab) = convert(XYZ, convert(LAB, c))

function xyz_to_uv(c::XYZ)
    d = c.x + 15c.y + 3c.z
    u = (4. * c.x) / d
    v = (9. * c.y) / d
    return (u,v)
end

function convert(::Type{XYZ}, c::LUV, wp::XYZ)
    (u_wp, v_wp) = xyz_to_uv(wp)

    a = (52 * c.l / (c.u + 13 * c.l * u_wp) - 1) / 3
    y = c.l > xyz_kappa * xyz_epsilon ? ((c.l + 16) / 116)^3 : c.l / xyz_kappa
    b = -5y
    d = y * (39 * c.l / (c.v + 13 * c.l * v_wp) - 5)
    x = (d - b) / (a + (1./3.))
    z = a * x + b

    XYZ(x, y, z)
end

convert(::Type{XYZ}, c::LUV)   = convert(XYZ, c, WP_DEFAULT)
convert(::Type{XYZ}, c::LCHuv) = convert(XYZ, convert(LUV, c))


# Everything to LAB
# -----------------

convert(::Type{LAB}, c::RGB) = convert(LAB, convert(XYZ, c))
convert(::Type{LAB}, c::HSV) = convert(LAB, convert(RGB, c))
convert(::Type{LAB}, c::HLS) = convert(LAB, convert(RGB, c))

function convert(::Type{LAB}, c::XYZ, wp::XYZ)
    function f(v::Float64)
        v > xyz_epsilon ? cbrt(v) : (xyz_kappa * v + 16) / 116
    end

    fx, fy, fz = f(c.x / wp.x), f(c.y / wp.y), f(c.z / wp.z)
    LAB(116fy - 16, 500(fx - fy), 200(fy - fz))
end

convert(::Type{LAB}, c::XYZ) = convert(LAB, c, WP_DEFAULT)

convert(::Type{LAB}, c::LUV)   = convert(LAB, convert(XYZ, c))
convert(::Type{LAB}, c::LCHuv) = convert(LAB, convert(XYZ, c))

function convert(::Type{LAB}, c::LCHab)
    hr = degrees2radians(c.h)
    LAB(c.l, c.c * cos(hr), c.c * sin(hr))
end


# Everything to LUV
# -----------------

convert(::Type{LUV}, c::RGB) = convert(LUV, convert(XYZ, c))
convert(::Type{LUV}, c::HSV) = convert(LUV, convert(RGB, c))
convert(::Type{LUV}, c::HLS) = convert(LUV, convert(RGB, c))

function convert(::Type{LUV}, c::XYZ, wp::XYZ)
    (u_wp, v_wp) = xyz_to_uv(wp)
    (u_, v_) = xyz_to_uv(c)

    y = c.y / wp.y

    l = y > xyz_epsilon ? 116 * cbrt(y) - 16 : xyz_kappa * y
    u = 13 * l * (u_ - u_wp)
    v = 13 * l * (v_ - v_wp)

    LUV(l, u, v)
end

convert(::Type{LUV}, c::XYZ) = convert(LUV, c, WP_DEFAULT)

convert(::Type{LUV}, c::LAB)   = convert(LUV, convert(XYZ, c))
convert(::Type{LUV}, c::LCHab) = convert(LUV, convert(XYZ, c))

function convert(::Type{LUV}, c::LCHuv)
    hr = degrees2radians(c.h)
    LUV(c.l, c.c * cos(hr), c.c * sin(hr))
end


# Everything to LCHuv
# -------------------

convert(::Type{LCHuv}, c::RGB) = convert(LCHuv, convert(XYZ, c))
convert(::Type{LCHuv}, c::HSV) = convert(LCHuv, convert(RGB, c))
convert(::Type{LCHuv}, c::HLS) = convert(LCHuv, convert(RGB, c))
convert(::Type{LCHuv}, c::XYZ) = convert(LCHuv, convert(LUV, c))
convert(::Type{LCHuv}, c::LAB) = convert(LCHuv, convert(LUV, c))

function convert(::Type{LCHuv}, c::LUV)
    h = radians2degrees(atan2(c.v, c.u))
    while h > 360; h -= 360; end
    while h < 0;   h += 360; end
    LCHuv(c.l, sqrt(c.u^2 + c.v^2), h)
end


# Everything to LCHab
# -------------------

convert(::Type{LCHab}, c::RGB) = convert(LCHab, convert(XYZ, c))
convert(::Type{LCHab}, c::HSV) = convert(LCHab, convert(RGB, c))
convert(::Type{LCHab}, c::HLS) = convert(LCHab, convert(RGB, c))
convert(::Type{LCHab}, c::XYZ) = convert(LCHab, convert(LUV, c))
convert(::Type{LCHab}, c::LUV) = convert(LCHab, convert(LAB, c))

function convert(::Type{LCHab}, c::LAB)
    h = radians2degrees(atan2(c.b, c.a))
    while h > 360; h -= 360; end
    while h < 0;   h += 360; end
    LCHab(c.l, sqrt(c.a^2 + c.b^2), h)
end


# Weighted mean of some number of colors within the same space.
#
# Args:
#  cs: Colors.
#  ws: Weights of the same length as cs.
#
# Returns:
#   A weighted mean color of type T.
#
function weighted_color_mean{T <: Color, S <: Number}(
        cs::AbstractArray{T,1}, ws::AbstractArray{S,1})
    mu = T()
    sumws = sum(ws)
    for (c, w) in zip(cs, ws)
        w /= sumws
        for v in names(T)
            setfield(mu, v, getfield(mu, v) + w * getfield(c, v))
        end
    end

    mu
end


# X11 Named Colors
# ----------------

const x11_color_names = {
    "aliceblue"            => (240, 248, 255),
    "antiquewhite"         => (250, 235, 215),
    "antiquewhite1"        => (255, 239, 219),
    "antiquewhite2"        => (238, 223, 204),
    "antiquewhite3"        => (205, 192, 176),
    "antiquewhite4"        => (139, 131, 120),
    "aquamarine"           => (127, 255, 212),
    "aquamarine1"          => (127, 255, 212),
    "aquamarine2"          => (118, 238, 198),
    "aquamarine3"          => (102, 205, 170),
    "aquamarine4"          => ( 69, 139, 116),
    "azure"                => (240, 255, 255),
    "azure1"               => (240, 255, 255),
    "azure2"               => (224, 238, 238),
    "azure3"               => (193, 205, 205),
    "azure4"               => (131, 139, 139),
    "beige"                => (245, 245, 220),
    "bisque"               => (255, 228, 196),
    "bisque1"              => (255, 228, 196),
    "bisque2"              => (238, 213, 183),
    "bisque3"              => (205, 183, 158),
    "bisque4"              => (139, 125, 107),
    "black"                => (  0,   0,   0),
    "blanchedalmond"       => (255, 235, 205),
    "blue"                 => (  0,   0, 255),
    "blue1"                => (  0,   0, 255),
    "blue2"                => (  0,   0, 238),
    "blue3"                => (  0,   0, 205),
    "blue4"                => (  0,   0, 139),
    "blueviolet"           => (138,  43, 226),
    "brown"                => (165,  42,  42),
    "brown1"               => (255,  64,  64),
    "brown2"               => (238,  59,  59),
    "brown3"               => (205,  51,  51),
    "brown4"               => (139,  35,  35),
    "burlywood"            => (222, 184, 135),
    "burlywood1"           => (255, 211, 155),
    "burlywood2"           => (238, 197, 145),
    "burlywood3"           => (205, 170, 125),
    "burlywood4"           => (139, 115,  85),
    "cadetblue"            => ( 95, 158, 160),
    "cadetblue1"           => (152, 245, 255),
    "cadetblue2"           => (142, 229, 238),
    "cadetblue3"           => (122, 197, 205),
    "cadetblue4"           => ( 83, 134, 139),
    "chartreuse"           => (127, 255,   0),
    "chartreuse1"          => (127, 255,   0),
    "chartreuse2"          => (118, 238,   0),
    "chartreuse3"          => (102, 205,   0),
    "chartreuse4"          => ( 69, 139,   0),
    "chocolate"            => (210, 105,  30),
    "chocolate1"           => (255, 127,  36),
    "chocolate2"           => (238, 118,  33),
    "chocolate3"           => (205, 102,  29),
    "chocolate4"           => (139,  69,  19),
    "coral"                => (255, 127,  80),
    "coral1"               => (255, 114,  86),
    "coral2"               => (238, 106,  80),
    "coral3"               => (205,  91,  69),
    "coral4"               => (139,  62,  47),
    "cornflowerblue"       => (100, 149, 237),
    "cornsilk"             => (255, 248, 220),
    "cornsilk1"            => (255, 248, 220),
    "cornsilk2"            => (238, 232, 205),
    "cornsilk3"            => (205, 200, 177),
    "cornsilk4"            => (139, 136, 120),
    "cyan"                 => (  0, 255, 255),
    "cyan1"                => (  0, 255, 255),
    "cyan2"                => (  0, 238, 238),
    "cyan3"                => (  0, 205, 205),
    "cyan4"                => (  0, 139, 139),
    "darkblue"             => (  0,   0, 139),
    "darkcyan"             => (  0, 139, 139),
    "darkgoldenrod"        => (184, 134,  11),
    "darkgoldenrod1"       => (255, 185,  15),
    "darkgoldenrod2"       => (238, 173,  14),
    "darkgoldenrod3"       => (205, 149,  12),
    "darkgoldenrod4"       => (139, 101,   8),
    "darkgray"             => (169, 169, 169),
    "darkgreen"            => (  0, 100,   0),
    "darkgrey"             => (169, 169, 169),
    "darkkhaki"            => (189, 183, 107),
    "darkmagenta"          => (139,   0, 139),
    "darkolivegreen"       => ( 85, 107,  47),
    "darkolivegreen1"      => (202, 255, 112),
    "darkolivegreen2"      => (188, 238, 104),
    "darkolivegreen3"      => (162, 205,  90),
    "darkolivegreen4"      => (110, 139,  61),
    "darkorange"           => (255, 140,   0),
    "darkorange1"          => (255, 127,   0),
    "darkorange2"          => (238, 118,   0),
    "darkorange3"          => (205, 102,   0),
    "darkorange4"          => (139,  69,   0),
    "darkorchid"           => (153,  50, 204),
    "darkorchid1"          => (191,  62, 255),
    "darkorchid2"          => (178,  58, 238),
    "darkorchid3"          => (154,  50, 205),
    "darkorchid4"          => (104,  34, 139),
    "darkred"              => (139,   0,   0),
    "darksalmon"           => (233, 150, 122),
    "darkseagreen"         => (143, 188, 143),
    "darkseagreen1"        => (193, 255, 193),
    "darkseagreen2"        => (180, 238, 180),
    "darkseagreen3"        => (155, 205, 155),
    "darkseagreen4"        => (105, 139, 105),
    "darkslateblue"        => ( 72,  61, 139),
    "darkslategray"        => ( 47,  79,  79),
    "darkslategray1"       => (151, 255, 255),
    "darkslategray2"       => (141, 238, 238),
    "darkslategray3"       => (121, 205, 205),
    "darkslategray4"       => ( 82, 139, 139),
    "darkslategrey"        => ( 47,  79,  79),
    "darkturquoise"        => (  0, 206, 209),
    "darkviolet"           => (148,   0, 211),
    "deeppink"             => (255,  20, 147),
    "deeppink1"            => (255,  20, 147),
    "deeppink2"            => (238,  18, 137),
    "deeppink3"            => (205,  16, 118),
    "deeppink4"            => (139,  10,  80),
    "deepskyblue"          => (  0, 191, 255),
    "deepskyblue1"         => (  0, 191, 255),
    "deepskyblue2"         => (  0, 178, 238),
    "deepskyblue3"         => (  0, 154, 205),
    "deepskyblue4"         => (  0, 104, 139),
    "dimgray"              => (105, 105, 105),
    "dimgrey"              => (105, 105, 105),
    "dodgerblue"           => ( 30, 144, 255),
    "dodgerblue1"          => ( 30, 144, 255),
    "dodgerblue2"          => ( 28, 134, 238),
    "dodgerblue3"          => ( 24, 116, 205),
    "dodgerblue4"          => ( 16,  78, 139),
    "firebrick"            => (178,  34,  34),
    "firebrick1"           => (255,  48,  48),
    "firebrick2"           => (238,  44,  44),
    "firebrick3"           => (205,  38,  38),
    "firebrick4"           => (139,  26,  26),
    "floralwhite"          => (255, 250, 240),
    "forestgreen"          => ( 34, 139,  34),
    "gainsboro"            => (220, 220, 220),
    "ghostwhite"           => (248, 248, 255),
    "gold"                 => (255, 215,   0),
    "gold1"                => (255, 215,   0),
    "gold2"                => (238, 201,   0),
    "gold3"                => (205, 173,   0),
    "gold4"                => (139, 117,   0),
    "goldenrod"            => (218, 165,  32),
    "goldenrod1"           => (255, 193,  37),
    "goldenrod2"           => (238, 180,  34),
    "goldenrod3"           => (205, 155,  29),
    "goldenrod4"           => (139, 105,  20),
    "gray"                 => (190, 190, 190),
    "gray0"                => (  0,   0,   0),
    "gray1"                => (  3,   3,   3),
    "gray2"                => (  5,   5,   5),
    "gray3"                => (  8,   8,   8),
    "gray4"                => ( 10,  10,  10),
    "gray5"                => ( 13,  13,  13),
    "gray6"                => ( 15,  15,  15),
    "gray7"                => ( 18,  18,  18),
    "gray8"                => ( 20,  20,  20),
    "gray9"                => ( 23,  23,  23),
    "gray10"               => ( 26,  26,  26),
    "gray11"               => ( 28,  28,  28),
    "gray12"               => ( 31,  31,  31),
    "gray13"               => ( 33,  33,  33),
    "gray14"               => ( 36,  36,  36),
    "gray15"               => ( 38,  38,  38),
    "gray16"               => ( 41,  41,  41),
    "gray17"               => ( 43,  43,  43),
    "gray18"               => ( 46,  46,  46),
    "gray19"               => ( 48,  48,  48),
    "gray20"               => ( 51,  51,  51),
    "gray21"               => ( 54,  54,  54),
    "gray22"               => ( 56,  56,  56),
    "gray23"               => ( 59,  59,  59),
    "gray24"               => ( 61,  61,  61),
    "gray25"               => ( 64,  64,  64),
    "gray26"               => ( 66,  66,  66),
    "gray27"               => ( 69,  69,  69),
    "gray28"               => ( 71,  71,  71),
    "gray29"               => ( 74,  74,  74),
    "gray30"               => ( 77,  77,  77),
    "gray31"               => ( 79,  79,  79),
    "gray32"               => ( 82,  82,  82),
    "gray33"               => ( 84,  84,  84),
    "gray34"               => ( 87,  87,  87),
    "gray35"               => ( 89,  89,  89),
    "gray36"               => ( 92,  92,  92),
    "gray37"               => ( 94,  94,  94),
    "gray38"               => ( 97,  97,  97),
    "gray39"               => ( 99,  99,  99),
    "gray40"               => (102, 102, 102),
    "gray41"               => (105, 105, 105),
    "gray42"               => (107, 107, 107),
    "gray43"               => (110, 110, 110),
    "gray44"               => (112, 112, 112),
    "gray45"               => (115, 115, 115),
    "gray46"               => (117, 117, 117),
    "gray47"               => (120, 120, 120),
    "gray48"               => (122, 122, 122),
    "gray49"               => (125, 125, 125),
    "gray50"               => (127, 127, 127),
    "gray51"               => (130, 130, 130),
    "gray52"               => (133, 133, 133),
    "gray53"               => (135, 135, 135),
    "gray54"               => (138, 138, 138),
    "gray55"               => (140, 140, 140),
    "gray56"               => (143, 143, 143),
    "gray57"               => (145, 145, 145),
    "gray58"               => (148, 148, 148),
    "gray59"               => (150, 150, 150),
    "gray60"               => (153, 153, 153),
    "gray61"               => (156, 156, 156),
    "gray62"               => (158, 158, 158),
    "gray63"               => (161, 161, 161),
    "gray64"               => (163, 163, 163),
    "gray65"               => (166, 166, 166),
    "gray66"               => (168, 168, 168),
    "gray67"               => (171, 171, 171),
    "gray68"               => (173, 173, 173),
    "gray69"               => (176, 176, 176),
    "gray70"               => (179, 179, 179),
    "gray71"               => (181, 181, 181),
    "gray72"               => (184, 184, 184),
    "gray73"               => (186, 186, 186),
    "gray74"               => (189, 189, 189),
    "gray75"               => (191, 191, 191),
    "gray76"               => (194, 194, 194),
    "gray77"               => (196, 196, 196),
    "gray78"               => (199, 199, 199),
    "gray79"               => (201, 201, 201),
    "gray80"               => (204, 204, 204),
    "gray81"               => (207, 207, 207),
    "gray82"               => (209, 209, 209),
    "gray83"               => (212, 212, 212),
    "gray84"               => (214, 214, 214),
    "gray85"               => (217, 217, 217),
    "gray86"               => (219, 219, 219),
    "gray87"               => (222, 222, 222),
    "gray88"               => (224, 224, 224),
    "gray89"               => (227, 227, 227),
    "gray90"               => (229, 229, 229),
    "gray91"               => (232, 232, 232),
    "gray92"               => (235, 235, 235),
    "gray93"               => (237, 237, 237),
    "gray94"               => (240, 240, 240),
    "gray95"               => (242, 242, 242),
    "gray96"               => (245, 245, 245),
    "gray97"               => (247, 247, 247),
    "gray98"               => (250, 250, 250),
    "gray99"               => (252, 252, 252),
    "gray100"              => (255, 255, 255),
    "green"                => (  0, 255,   0),
    "green1"               => (  0, 255,   0),
    "green2"               => (  0, 238,   0),
    "green3"               => (  0, 205,   0),
    "green4"               => (  0, 139,   0),
    "greenyellow"          => (173, 255,  47),
    "grey"                 => (190, 190, 190),
    "grey0"                => (  0,   0,   0),
    "grey1"                => (  3,   3,   3),
    "grey2"                => (  5,   5,   5),
    "grey3"                => (  8,   8,   8),
    "grey4"                => ( 10,  10,  10),
    "grey5"                => ( 13,  13,  13),
    "grey6"                => ( 15,  15,  15),
    "grey7"                => ( 18,  18,  18),
    "grey8"                => ( 20,  20,  20),
    "grey9"                => ( 23,  23,  23),
    "grey10"               => ( 26,  26,  26),
    "grey11"               => ( 28,  28,  28),
    "grey12"               => ( 31,  31,  31),
    "grey13"               => ( 33,  33,  33),
    "grey14"               => ( 36,  36,  36),
    "grey15"               => ( 38,  38,  38),
    "grey16"               => ( 41,  41,  41),
    "grey17"               => ( 43,  43,  43),
    "grey18"               => ( 46,  46,  46),
    "grey19"               => ( 48,  48,  48),
    "grey20"               => ( 51,  51,  51),
    "grey21"               => ( 54,  54,  54),
    "grey22"               => ( 56,  56,  56),
    "grey23"               => ( 59,  59,  59),
    "grey24"               => ( 61,  61,  61),
    "grey25"               => ( 64,  64,  64),
    "grey26"               => ( 66,  66,  66),
    "grey27"               => ( 69,  69,  69),
    "grey28"               => ( 71,  71,  71),
    "grey29"               => ( 74,  74,  74),
    "grey30"               => ( 77,  77,  77),
    "grey31"               => ( 79,  79,  79),
    "grey32"               => ( 82,  82,  82),
    "grey33"               => ( 84,  84,  84),
    "grey34"               => ( 87,  87,  87),
    "grey35"               => ( 89,  89,  89),
    "grey36"               => ( 92,  92,  92),
    "grey37"               => ( 94,  94,  94),
    "grey38"               => ( 97,  97,  97),
    "grey39"               => ( 99,  99,  99),
    "grey40"               => (102, 102, 102),
    "grey41"               => (105, 105, 105),
    "grey42"               => (107, 107, 107),
    "grey43"               => (110, 110, 110),
    "grey44"               => (112, 112, 112),
    "grey45"               => (115, 115, 115),
    "grey46"               => (117, 117, 117),
    "grey47"               => (120, 120, 120),
    "grey48"               => (122, 122, 122),
    "grey49"               => (125, 125, 125),
    "grey50"               => (127, 127, 127),
    "grey51"               => (130, 130, 130),
    "grey52"               => (133, 133, 133),
    "grey53"               => (135, 135, 135),
    "grey54"               => (138, 138, 138),
    "grey55"               => (140, 140, 140),
    "grey56"               => (143, 143, 143),
    "grey57"               => (145, 145, 145),
    "grey58"               => (148, 148, 148),
    "grey59"               => (150, 150, 150),
    "grey60"               => (153, 153, 153),
    "grey61"               => (156, 156, 156),
    "grey62"               => (158, 158, 158),
    "grey63"               => (161, 161, 161),
    "grey64"               => (163, 163, 163),
    "grey65"               => (166, 166, 166),
    "grey66"               => (168, 168, 168),
    "grey67"               => (171, 171, 171),
    "grey68"               => (173, 173, 173),
    "grey69"               => (176, 176, 176),
    "grey70"               => (179, 179, 179),
    "grey71"               => (181, 181, 181),
    "grey72"               => (184, 184, 184),
    "grey73"               => (186, 186, 186),
    "grey74"               => (189, 189, 189),
    "grey75"               => (191, 191, 191),
    "grey76"               => (194, 194, 194),
    "grey77"               => (196, 196, 196),
    "grey78"               => (199, 199, 199),
    "grey79"               => (201, 201, 201),
    "grey80"               => (204, 204, 204),
    "grey81"               => (207, 207, 207),
    "grey82"               => (209, 209, 209),
    "grey83"               => (212, 212, 212),
    "grey84"               => (214, 214, 214),
    "grey85"               => (217, 217, 217),
    "grey86"               => (219, 219, 219),
    "grey87"               => (222, 222, 222),
    "grey88"               => (224, 224, 224),
    "grey89"               => (227, 227, 227),
    "grey90"               => (229, 229, 229),
    "grey91"               => (232, 232, 232),
    "grey92"               => (235, 235, 235),
    "grey93"               => (237, 237, 237),
    "grey94"               => (240, 240, 240),
    "grey95"               => (242, 242, 242),
    "grey96"               => (245, 245, 245),
    "grey97"               => (247, 247, 247),
    "grey98"               => (250, 250, 250),
    "grey99"               => (252, 252, 252),
    "grey100"              => (255, 255, 255),
    "honeydew"             => (240, 255, 240),
    "honeydew1"            => (240, 255, 240),
    "honeydew2"            => (224, 238, 224),
    "honeydew3"            => (193, 205, 193),
    "honeydew4"            => (131, 139, 131),
    "hotpink"              => (255, 105, 180),
    "hotpink1"             => (255, 110, 180),
    "hotpink2"             => (238, 106, 167),
    "hotpink3"             => (205,  96, 144),
    "hotpink4"             => (139,  58,  98),
    "indianred"            => (205,  92,  92),
    "indianred1"           => (255, 106, 106),
    "indianred2"           => (238,  99,  99),
    "indianred3"           => (205,  85,  85),
    "indianred4"           => (139,  58,  58),
    "ivory"                => (255, 255, 240),
    "ivory1"               => (255, 255, 240),
    "ivory2"               => (238, 238, 224),
    "ivory3"               => (205, 205, 193),
    "ivory4"               => (139, 139, 131),
    "khaki"                => (240, 230, 140),
    "khaki1"               => (255, 246, 143),
    "khaki2"               => (238, 230, 133),
    "khaki3"               => (205, 198, 115),
    "khaki4"               => (139, 134,  78),
    "lavender"             => (230, 230, 250),
    "lavenderblush"        => (255, 240, 245),
    "lavenderblush1"       => (255, 240, 245),
    "lavenderblush2"       => (238, 224, 229),
    "lavenderblush3"       => (205, 193, 197),
    "lavenderblush4"       => (139, 131, 134),
    "lawngreen"            => (124, 252,   0),
    "lemonchiffon"         => (255, 250, 205),
    "lemonchiffon1"        => (255, 250, 205),
    "lemonchiffon2"        => (238, 233, 191),
    "lemonchiffon3"        => (205, 201, 165),
    "lemonchiffon4"        => (139, 137, 112),
    "lightblue"            => (173, 216, 230),
    "lightblue1"           => (191, 239, 255),
    "lightblue2"           => (178, 223, 238),
    "lightblue3"           => (154, 192, 205),
    "lightblue4"           => (104, 131, 139),
    "lightcoral"           => (240, 128, 128),
    "lightcyan"            => (224, 255, 255),
    "lightcyan1"           => (224, 255, 255),
    "lightcyan2"           => (209, 238, 238),
    "lightcyan3"           => (180, 205, 205),
    "lightcyan4"           => (122, 139, 139),
    "lightgoldenrod"       => (238, 221, 130),
    "lightgoldenrod1"      => (255, 236, 139),
    "lightgoldenrod2"      => (238, 220, 130),
    "lightgoldenrod3"      => (205, 190, 112),
    "lightgoldenrod4"      => (139, 129,  76),
    "lightgoldenrodyellow" => (250, 250, 210),
    "lightgray"            => (211, 211, 211),
    "lightgreen"           => (144, 238, 144),
    "lightgrey"            => (211, 211, 211),
    "lightpink"            => (255, 182, 193),
    "lightpink1"           => (255, 174, 185),
    "lightpink2"           => (238, 162, 173),
    "lightpink3"           => (205, 140, 149),
    "lightpink4"           => (139,  95, 101),
    "lightsalmon"          => (255, 160, 122),
    "lightsalmon1"         => (255, 160, 122),
    "lightsalmon2"         => (238, 149, 114),
    "lightsalmon3"         => (205, 129,  98),
    "lightsalmon4"         => (139,  87,  66),
    "lightseagreen"        => ( 32, 178, 170),
    "lightskyblue"         => (135, 206, 250),
    "lightskyblue1"        => (176, 226, 255),
    "lightskyblue2"        => (164, 211, 238),
    "lightskyblue3"        => (141, 182, 205),
    "lightskyblue4"        => ( 96, 123, 139),
    "lightslateblue"       => (132, 112, 255),
    "lightslategray"       => (119, 136, 153),
    "lightslategrey"       => (119, 136, 153),
    "lightsteelblue"       => (176, 196, 222),
    "lightsteelblue1"      => (202, 225, 255),
    "lightsteelblue2"      => (188, 210, 238),
    "lightsteelblue3"      => (162, 181, 205),
    "lightsteelblue4"      => (110, 123, 139),
    "lightyellow"          => (255, 255, 224),
    "lightyellow1"         => (255, 255, 224),
    "lightyellow2"         => (238, 238, 209),
    "lightyellow3"         => (205, 205, 180),
    "lightyellow4"         => (139, 139, 122),
    "limegreen"            => ( 50, 205,  50),
    "linen"                => (250, 240, 230),
    "magenta"              => (255,   0, 255),
    "magenta1"             => (255,   0, 255),
    "magenta2"             => (238,   0, 238),
    "magenta3"             => (205,   0, 205),
    "magenta4"             => (139,   0, 139),
    "maroon"               => (176,  48,  96),
    "maroon1"              => (255,  52, 179),
    "maroon2"              => (238,  48, 167),
    "maroon3"              => (205,  41, 144),
    "maroon4"              => (139,  28,  98),
    "mediumaquamarine"     => (102, 205, 170),
    "mediumblue"           => (  0,   0, 205),
    "mediumorchid"         => (186,  85, 211),
    "mediumorchid1"        => (224, 102, 255),
    "mediumorchid2"        => (209,  95, 238),
    "mediumorchid3"        => (180,  82, 205),
    "mediumorchid4"        => (122,  55, 139),
    "mediumpurple"         => (147, 112, 219),
    "mediumpurple1"        => (171, 130, 255),
    "mediumpurple2"        => (159, 121, 238),
    "mediumpurple3"        => (137, 104, 205),
    "mediumpurple4"        => ( 93,  71, 139),
    "mediumseagreen"       => ( 60, 179, 113),
    "mediumslateblue"      => (123, 104, 238),
    "mediumspringgreen"    => (  0, 250, 154),
    "mediumturquoise"      => ( 72, 209, 204),
    "mediumvioletred"      => (199,  21, 133),
    "midnightblue"         => ( 25,  25, 112),
    "mintcream"            => (245, 255, 250),
    "mistyrose"            => (255, 228, 225),
    "mistyrose1"           => (255, 228, 225),
    "mistyrose2"           => (238, 213, 210),
    "mistyrose3"           => (205, 183, 181),
    "mistyrose4"           => (139, 125, 123),
    "moccasin"             => (255, 228, 181),
    "navajowhite"          => (255, 222, 173),
    "navajowhite1"         => (255, 222, 173),
    "navajowhite2"         => (238, 207, 161),
    "navajowhite3"         => (205, 179, 139),
    "navajowhite4"         => (139, 121,  94),
    "navy"                 => (  0,   0, 128),
    "navyblue"             => (  0,   0, 128),
    "oldlace"              => (253, 245, 230),
    "olivedrab"            => (107, 142,  35),
    "olivedrab1"           => (192, 255,  62),
    "olivedrab2"           => (179, 238,  58),
    "olivedrab3"           => (154, 205,  50),
    "olivedrab4"           => (105, 139,  34),
    "orange"               => (255, 165,   0),
    "orange1"              => (255, 165,   0),
    "orange2"              => (238, 154,   0),
    "orange3"              => (205, 133,   0),
    "orange4"              => (139,  90,   0),
    "orangered"            => (255,  69,   0),
    "orangered1"           => (255,  69,   0),
    "orangered2"           => (238,  64,   0),
    "orangered3"           => (205,  55,   0),
    "orangered4"           => (139,  37,   0),
    "orchid"               => (218, 112, 214),
    "orchid1"              => (255, 131, 250),
    "orchid2"              => (238, 122, 233),
    "orchid3"              => (205, 105, 201),
    "orchid4"              => (139,  71, 137),
    "palegoldenrod"        => (238, 232, 170),
    "palegreen"            => (152, 251, 152),
    "palegreen1"           => (154, 255, 154),
    "palegreen2"           => (144, 238, 144),
    "palegreen3"           => (124, 205, 124),
    "palegreen4"           => ( 84, 139,  84),
    "paleturquoise"        => (175, 238, 238),
    "paleturquoise1"       => (187, 255, 255),
    "paleturquoise2"       => (174, 238, 238),
    "paleturquoise3"       => (150, 205, 205),
    "paleturquoise4"       => (102, 139, 139),
    "palevioletred"        => (219, 112, 147),
    "palevioletred1"       => (255, 130, 171),
    "palevioletred2"       => (238, 121, 159),
    "palevioletred3"       => (205, 104, 137),
    "palevioletred4"       => (139,  71,  93),
    "papayawhip"           => (255, 239, 213),
    "peachpuff"            => (255, 218, 185),
    "peachpuff1"           => (255, 218, 185),
    "peachpuff2"           => (238, 203, 173),
    "peachpuff3"           => (205, 175, 149),
    "peachpuff4"           => (139, 119, 101),
    "peru"                 => (205, 133,  63),
    "pink"                 => (255, 192, 203),
    "pink1"                => (255, 181, 197),
    "pink2"                => (238, 169, 184),
    "pink3"                => (205, 145, 158),
    "pink4"                => (139,  99, 108),
    "plum"                 => (221, 160, 221),
    "plum1"                => (255, 187, 255),
    "plum2"                => (238, 174, 238),
    "plum3"                => (205, 150, 205),
    "plum4"                => (139, 102, 139),
    "powderblue"           => (176, 224, 230),
    "purple"               => (160,  32, 240),
    "purple1"              => (155,  48, 255),
    "purple2"              => (145,  44, 238),
    "purple3"              => (125,  38, 205),
    "purple4"              => ( 85,  26, 139),
    "red"                  => (255,   0,   0),
    "red1"                 => (255,   0,   0),
    "red2"                 => (238,   0,   0),
    "red3"                 => (205,   0,   0),
    "red4"                 => (139,   0,   0),
    "rosybrown"            => (188, 143, 143),
    "rosybrown1"           => (255, 193, 193),
    "rosybrown2"           => (238, 180, 180),
    "rosybrown3"           => (205, 155, 155),
    "rosybrown4"           => (139, 105, 105),
    "royalblue"            => ( 65, 105, 225),
    "royalblue1"           => ( 72, 118, 255),
    "royalblue2"           => ( 67, 110, 238),
    "royalblue3"           => ( 58,  95, 205),
    "royalblue4"           => ( 39,  64, 139),
    "saddlebrown"          => (139,  69,  19),
    "salmon"               => (250, 128, 114),
    "salmon1"              => (255, 140, 105),
    "salmon2"              => (238, 130,  98),
    "salmon3"              => (205, 112,  84),
    "salmon4"              => (139,  76,  57),
    "sandybrown"           => (244, 164,  96),
    "seagreen"             => ( 46, 139,  87),
    "seagreen1"            => ( 84, 255, 159),
    "seagreen2"            => ( 78, 238, 148),
    "seagreen3"            => ( 67, 205, 128),
    "seagreen4"            => ( 46, 139,  87),
    "seashell"             => (255, 245, 238),
    "seashell1"            => (255, 245, 238),
    "seashell2"            => (238, 229, 222),
    "seashell3"            => (205, 197, 191),
    "seashell4"            => (139, 134, 130),
    "sienna"               => (160,  82,  45),
    "sienna1"              => (255, 130,  71),
    "sienna2"              => (238, 121,  66),
    "sienna3"              => (205, 104,  57),
    "sienna4"              => (139,  71,  38),
    "skyblue"              => (135, 206, 235),
    "skyblue1"             => (135, 206, 255),
    "skyblue2"             => (126, 192, 238),
    "skyblue3"             => (108, 166, 205),
    "skyblue4"             => ( 74, 112, 139),
    "slateblue"            => (106,  90, 205),
    "slateblue1"           => (131, 111, 255),
    "slateblue2"           => (122, 103, 238),
    "slateblue3"           => (105,  89, 205),
    "slateblue4"           => ( 71,  60, 139),
    "slategray"            => (112, 128, 144),
    "slategray1"           => (198, 226, 255),
    "slategray2"           => (185, 211, 238),
    "slategray3"           => (159, 182, 205),
    "slategray4"           => (108, 123, 139),
    "slategrey"            => (112, 128, 144),
    "snow"                 => (255, 250, 250),
    "snow1"                => (255, 250, 250),
    "snow2"                => (238, 233, 233),
    "snow3"                => (205, 201, 201),
    "snow4"                => (139, 137, 137),
    "springgreen"          => (  0, 255, 127),
    "springgreen1"         => (  0, 255, 127),
    "springgreen2"         => (  0, 238, 118),
    "springgreen3"         => (  0, 205, 102),
    "springgreen4"         => (  0, 139,  69),
    "steelblue"            => ( 70, 130, 180),
    "steelblue1"           => ( 99, 184, 255),
    "steelblue2"           => ( 92, 172, 238),
    "steelblue3"           => ( 79, 148, 205),
    "steelblue4"           => ( 54, 100, 139),
    "tan"                  => (210, 180, 140),
    "tan1"                 => (255, 165,  79),
    "tan2"                 => (238, 154,  73),
    "tan3"                 => (205, 133,  63),
    "tan4"                 => (139,  90,  43),
    "thistle"              => (216, 191, 216),
    "thistle1"             => (255, 225, 255),
    "thistle2"             => (238, 210, 238),
    "thistle3"             => (205, 181, 205),
    "thistle4"             => (139, 123, 139),
    "tomato"               => (255,  99,  71),
    "tomato1"              => (255,  99,  71),
    "tomato2"              => (238,  92,  66),
    "tomato3"              => (205,  79,  57),
    "tomato4"              => (139,  54,  38),
    "turquoise"            => ( 64, 224, 208),
    "turquoise1"           => (  0, 245, 255),
    "turquoise2"           => (  0, 229, 238),
    "turquoise3"           => (  0, 197, 205),
    "turquoise4"           => (  0, 134, 139),
    "violet"               => (238, 130, 238),
    "violetred"            => (208,  32, 144),
    "violetred1"           => (255,  62, 150),
    "violetred2"           => (238,  58, 140),
    "violetred3"           => (205,  50, 120),
    "violetred4"           => (139,  34,  82),
    "wheat"                => (245, 222, 179),
    "wheat1"               => (255, 231, 186),
    "wheat2"               => (238, 216, 174),
    "wheat3"               => (205, 186, 150),
    "wheat4"               => (139, 126, 102),
    "white"                => (255, 255, 255),
    "whitesmoke"           => (245, 245, 245),
    "yellow"               => (255, 255,   0),
    "yellow1"              => (255, 255,   0),
    "yellow2"              => (238, 238,   0),
    "yellow3"              => (205, 205,   0),
    "yellow4"              => (139, 139,   0),
    "yellowgreen"          => (154, 205,  50)
}

const col_pat_hex1 = r"(#|0x)([[:xdigit:]])([[:xdigit:]])([[:xdigit:]])"
const col_pat_hex2 = r"(#|0x)([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})"
const col_pat_rgb  = r"rgb\((\d+),(\d+),(\d+)\)"

color(c::Color) = c

function color(desc::String)
    local desc_ = replace(desc, " ", "")

    mat = match(col_pat_hex2, desc_)
    if mat != nothing
        return RGB(parse_int(mat.captures[2], 16) / 255.,
                   parse_int(mat.captures[3], 16) / 255.,
                   parse_int(mat.captures[4], 16) / 255.)
    end

    local mat = match(col_pat_hex1, desc_)
    if mat != nothing
        return RGB((16 * parse_int(mat.captures[2], 16)) / 255.,
                   (16 * parse_int(mat.captures[3], 16)) / 255.,
                   (16 * parse_int(mat.captures[4], 16)) / 255.)
    end

    mat = match(col_pat_rgb, desc_)
    if mat != nothing
        return RGB(parse_int(mat.captures[1], 10) / 255.,
                   parse_int(mat.captures[2], 10) / 255.,
                   parse_int(mat.captures[3], 10) / 255.)
    end

    local c
    try
        c = x11_color_names[lowercase(desc_)]
    catch
        error("Unknown color: ", desc)
    end

    return RGB(c[1] / 255., c[2] / 255., c[3] / 255.)
end

colour = color


function cssfmt(c::Color)
    hex(convert(RGB, c))
end


function cssfmt(c::Nothing)
    "none"
end


function json(c::Color)
    quote_string(cssfmt(c))
end


