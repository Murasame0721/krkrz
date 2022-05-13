;# make stub C source for exporting TVPs internal functions.
$copyright = <<EOF;
/*

	TVP2 ( T Visual Presenter 2 )  A script authoring tool
	Copyright (C) 2000-2009 W.Dee <dee\@kikyou.info> and contributors

	See details of license at "license.txt"
*/
/* This file is always generated by makestub.pl . */
/* Modification by hand will be lost. */
EOF


use Compress::Zlib;
use Digest::MD5  qw(md5 md5_hex md5_base64);


$output_tpstub_h = "../../../plugins/win32/tp_stub.h";
$output_tpstub_cpp = "../../../plugins/win32/tp_stub.cpp";

;# This perl script is VERY VERY complicated so I do never want to see again.

$num = 0;

sub normalize_string
{
	local($str, $ret, @array, @array2);
	$str = $_[0];
	$str =~ s/^\s*(.*?)\s*$/$1/;
	$str =~ s/\*\*/\* \*/g;
	$str =~ s/\*\*/\* \*/g;
	@array = split(/\s|\b/, $str);
	foreach $str (@array)
	{
		if($str !~ /\s/ && $str ne '')
		{
			push(@array2, $str);
		}
	}
	$str = join(' ', @array2);
	return $str;
}

sub get_arg_names
{
	local($args, $arg, @array);
	$args = $_[0];
	@array = split(/,/, $args);
	$args = '';
	foreach $arg ( @array )
	{
		$arg =~ s/^\s*(.*?)\s*$/$1/;
		if($arg =~ /^(.*)=(.*)$/)
		{
			$arg = $1;
		}
		$arg =~ s/^\s*(.*?)\s*$/$1/;
		$arg =~ /(\w+)$/;
		$args .= ', ' if $args ne '';
		$args .= $1;
	}
	return $args;
}

sub except_arg_names
{
	local($args, $arg, @array);
	$args = $_[0];
	@array = split(/,/, $args);
	$args = '';
	foreach $arg ( @array )
	{
		$arg =~ s/^\s*(.*?)\s*$/$1/;
		if($arg =~ /^(.*)=(.*)$/)
		{
			$arg = $1;
		}
		$arg =~ s/^\s*(.*?)\s*$/$1/;
		$arg =~ s/(.*?)(\w+)$/$1/;
		$arg =~ s/^\s*(.*?)\s*$/$1/;
		$args .= ',' if $args ne '';
		$args .= normalize_string($1);
	}
	return $args;
}

sub get_ret_type
{
	local($type, $prefix);
	$type = $_[0];
	$prefix = $_[1];

	if($type eq "${prefix}_METHOD_RET_EMPTY")
	{
		return 'void';
	}
	elsif($type =~ /${prefix}_METHOD_RET\((.*?)\)/)
	{
		return normalize_string($1);
	}
	return normalize_string($type);
}

sub make_func_stub
{
	local($rettype, $name, $arg, $type, $prefix, $isconst, $isstatic,
		$str, $mangled, $noreturn, $h, $argnames, $functype, $func_exp_name, $md5);
	$rettype = $_[0];
	$name = $_[1];
	$arg = $_[2];
	$type = $_[3];
	$prefix = $_[4];
	$isconst = $_[5];
	$isstatic = $_[6];

	$rettype =~ s/\n/ /gs;
	$rettype =~ s/\t/ /gs;
	$name =~ s/\n/ /gs;
	$name =~ s/\t/ /gs;
	$arg =~ s/\n/ /gs;
	$arg =~ s/\t/ /gs;

	$func_exp_name = 
		($rettype =~ /^${prefix}_METHOD_RET/ ? '' : normalize_string($rettype).' ').
		$type.'::'.normalize_string($name).'('.except_arg_names($arg).')'.($isconst ? ' const':'');

	$md5 = md5_hex($func_exp_name);

	$mangled = "TVP_Stub_$md5\t";
	$mangled .= $func_exp_name;
	$mangled .= "\t".get_ret_type($rettype, $prefix).
		"(__stdcall *  __TVP_Stub_$md5)($type *_this".($arg ne '' ? ', ' : '').normalize_string($arg).")";
	$mangled .= "\t".($rettype =~ /^${prefix}_METHOD_RET/ ? '' : normalize_string($rettype)) .
		" ".normalize_string($type)."::".normalize_string($name). "(".normalize_string($arg).")";
	$mangled .= "\tTVP_Stub_$md5";
	$mangled .= "\t$md5";
	$mangled .= "\t".get_arg_names($arg);
	$functype = get_ret_type($rettype, $prefix).
		"(__stdcall * __functype)(".($isconst ? "const ": "").
		($isstatic ? '' : ("$type *".($arg ne '' ? ', ' : ''))).
		normalize_string(except_arg_names($arg)).")";
	$mangled .= "\t".$functype;

	$noreturn = 0;
	if($rettype eq "${prefix}_METHOD_RET_EMPTY")
	{
		$noreturn = 1;
	}
	elsif($rettype =~ /${prefix}_METHOD_RET\((.*?)\)/)
	{
		$noreturn = 2;
	}

	$rettype = get_ret_type($rettype, $prefix);

	print OFH "static ";
	print OFH normalize_string($rettype);
	print OFH " __stdcall ";
	print OFH "TVP_Stub_$md5";
	if($isstatic)
	{
		print OFH "(";
	}
	else
	{
		print OFH "($type * _this";
		if($arg ne '')
		{
			print OFH ", ";
		}
	}

	print OFH normalize_string($arg);
	print OFH ")\n";
	print OFH "{\n";
	$argnames = get_arg_names($arg);
	if($name eq $type)
	{
		;# constructor
		print OFH "\t::new (_this) $name(".$argnames.");\n";
		$h = "\t".normalize_string($name)."(".normalize_string($arg).")\n".
			"\t{\n".
			"\t\tif(!TVPImportFuncPtr$md5)\n".
			"\t\t{\n".
			"\t\t\tstatic char funcname[] = \"$func_exp_name\";\n".
			"\t\t\tTVPImportFuncPtr$md5 = TVPGetImportFuncPtr(funcname);\n".
			"\t\t}\n".
			"\t\ttypedef $functype;\n".
			"\t\t((__functype)(TVPImportFuncPtr$md5))(".($isstatic ? '' : ("this".($argnames ne '' ? ', ' : ''))).$argnames.");\n".
			"\t}\n";
	}
	elsif($name eq "~$type")
	{
		;# destructor
		print OFH "\t_this->$name(".$argnames.");\n";
		$h = "\t".normalize_string($name)."(".normalize_string($arg).")\n".
			"\t{\n".
			"\t\tif(!TVPImportFuncPtr$md5)\n".
			"\t\t{\n".
			"\t\t\tstatic char funcname[] = \"$func_exp_name\";\n".
			"\t\t\tTVPImportFuncPtr$md5 = TVPGetImportFuncPtr(funcname);\n".
			"\t\t}\n".
			"\t\ttypedef $functype;\n".
			"\t\t((__functype)(TVPImportFuncPtr$md5))(".($isstatic ? '' : ("this".($argnames ne '' ? ', ' : ''))).$argnames.");\n".
			"\t}\n";
	}
	else
	{
		print OFH "\t";
		print OFH "return ";
		if($isstatic)
		{
			print OFH "${type}::$name(".$argnames.");\n";
		}
		else
		{
			print OFH "_this->$name(".$argnames.");\n";
		}
		$h = "\t".($isstatic ? 'static ' : '').($noreturn ? '' : $rettype.' ') . normalize_string($name). "(" . normalize_string($arg) .
			")".($isconst ? ' const' : '')."\n".
			"\t{\n".
			"\t\tif(!TVPImportFuncPtr$md5)\n".
			"\t\t{\n".
			"\t\t\tstatic char funcname[] = \"$func_exp_name\";\n".
			"\t\t\tTVPImportFuncPtr$md5 = TVPGetImportFuncPtr(funcname);\n".
			"\t\t}\n".
			"\t\ttypedef $functype;\n".
			"\t\t".(($rettype eq 'void') ? '' : 'return ').
			"((__functype)(TVPImportFuncPtr$md5))(".($isstatic ? '' : ("this".($argnames ne '' ? ', ' : ''))).$argnames.");\n".
			"\t}\n";
	}
	print OFH "}\n";

	push(@func_list, $mangled);
	push(@h_stub, $h);
	$num++;
}

sub list_func_stub
{
	local($prefix, $content, $type);
	$prefix = $_[0];
	$content = $_[1];
	$type = $_[2];

	while($content =~ /${prefix}_METHOD_DEF\(\s*(.*?)\s*,\s*(.*?)\s*,\s*\((.*?)\)\s*\)/sg)
	{
		&make_func_stub($1, $2, $3, $type, $prefix, 0, 0);
	}
	while($content =~ /${prefix}_CONST_METHOD_DEF\(\s*(.*?)\s*,\s*(.*?)\s*,\s*\((.*?)\)\s*\)/sg)
	{
		&make_func_stub($1, $2, $3, $type, $prefix, 1, 0);
	}
	while($content =~ /${prefix}_STATIC_METHOD_DEF\(\s*(.*?)\s*,\s*(.*?)\s*,\s*\((.*?)\)\s*\)/sg)
	{
		&make_func_stub($1, $2, $3, $type, $prefix, 0, 1);
	}
	while($content =~ /${prefix}_STATIC_CONST_METHOD_DEF\(\s*(.*?)\s*,\s*(.*?)\s*,\s*\((.*?)\)\s*\)/sg)
	{
		&make_func_stub($1, $2, $3, $type, $prefix, 1, 1);
	}
}


sub make_exp_stub
{
	local($rettype, $name, $arg, $type, $prefix, $isconst, $str, $mangled, $noreturn, $h, $argnames);
	$rettype = $_[0];
	$name = $_[1];
	$arg = $_[2];

	$rettype =~ s/\n/ /gs;
	$rettype =~ s/\t/ /gs;
	$name =~ s/\n/ /gs;
	$name =~ s/\t/ /gs;
	$arg =~ s/\n/ /gs;
	$arg =~ s/\t/ /gs;

	$func_exp_name = normalize_string($rettype).' '.
		'::'.normalize_string($name).'('.except_arg_names($arg).')';

	$md5 = md5_hex($func_exp_name);

	$mangled = "TVP_Stub_$md5\t".$func_exp_name;
	$mangled .= "\t".normalize_string($rettype).
		" (__stdcall *".normalize_string($name).")(".normalize_string($arg).")";
	$mangled .= "\t".normalize_string($rettype) . " ".normalize_string($name)."(".
		normalize_string($arg).")";
	$mangled .= "\t$name";
	$mangled .= "\t$md5";
	$mangled .= "\t".get_arg_names($arg);
	$mangled .= "\t".normalize_string($rettype).
		" (__stdcall * __functype)(".normalize_string(except_arg_names($arg)).")";
	$mangled .= "\t".normalize_string($rettype);

	print OFH "static ";
	print OFH normalize_string($rettype);
	print OFH " __stdcall ";
	print OFH "TVP_Stub_$md5(";
	print OFH normalize_string($arg);
	print OFH ")\n";
	print OFH "{\n";
	$argnames = get_arg_names($arg);
	print OFH "\t";
	print OFH "return ";
	print OFH "$name(".$argnames.");\n";
	print OFH "}\n";

	push(@func_list, $mangled);
	$num++;
}

sub process_exp_stub
{
	local($file);
	$file = $_[0];

	open FH, $file or die;
	$content = <FH>;

	while($content =~ /\/\*\[\*\/(.*?)\/\*\]\*\//gs)
	{
		$defs .= $1."\n";
	}

	while($content =~ /\/\*\[C\*\/(.*?)\/\*C]\*\//gs)
	{
		$impls .= $1."\n";
	}

	while($content =~ /TJS_EXP_FUNC_DEF\(\s*(.*?)\s*,\s*(.*?)\s*,\s*\((.*?)\)\s*\)/sg)
	{
		&make_exp_stub($1, $2, $3);
	}

	while($content =~ /TVP_GL_FUNC_PTR_EXTERN_DECL\(\s*(.*?)\s*,\s*(.*?)\s*,\s*\((.*?)\)\s*\)/sg)
	{
		&make_exp_stub($1, $2, $3);
	}

}

undef($/);
@func_list = ();

open(OFH, ">FuncStubs.~h") or die;

print OFH $copyright;

print OFH <<EOF;

extern void TVPExportFunctions();

EOF

open(OFH, ">FuncStubs.~cpp") or die;

print OFH $copyright;

print OFH <<EOF;


#include "tjsCommHead.h"

#include "tjsVariant.h"
#include "tjsString.h"
#include "PluginImpl.h"

EOF


open(FH, "../../tjs2/tjsVariant.h") or die;
$content = <FH>;
$content =~ /\/\*start-of-tTJSVariant\*\/(.*?)\/\*end-of-tTJSVariant\*\//s;
@h_stub = ();
&list_func_stub("TJS", $1, "tTJSVariant");
@variant = @h_stub;

$content =~ /\/\*start-of-tTJSVariantOctet\*\/(.*?)\/\*end-of-tTJSVariantOctet\*\//s;
@h_stub = ();
&list_func_stub("TJS", $1, "tTJSVariantOctet");
@variantoctet = @h_stub;

open(FH, "../../tjs2/tjsString.h") or die;
$content = <FH>;
$content =~ /\/\*start-of-tTJSString\*\/(.*?)\/\*end-of-tTJSString\*\//s;
@h_stub = ();
&list_func_stub("TJS", $1, "tTJSString");
@string = @h_stub;

open(FH, "../../tjs2/tjsVariantString.h") or die;
$content = <FH>;
$content =~ /\/\*start-of-tTJSVariantString\*\/(.*?)\/\*end-of-tTJSVariantString\*\//s;
@h_stub = ();
&list_func_stub("TJS", $1, "tTJSVariantString");
@variantstring = @h_stub;

$defs = '';
$impls = '';

@method_list = @func_list;

@func_list = ();

print OFH "#include \"tjsTypes.h\"\n";
process_exp_stub("../../tjs2/tjsTypes.h");

print OFH "#include \"tjsConfig.h\"\n";
process_exp_stub("../../tjs2/tjsConfig.h");

print OFH "#include \"tjsVariantString.h\"\n";
process_exp_stub("../../tjs2/tjsVariantString.h");

print OFH "#include \"tjsUtils.h\"\n";
process_exp_stub("../../tjs2/tjsUtils.h");

print OFH "#include \"tjsString.h\"\n";
process_exp_stub("../../tjs2/tjsString.h");

print OFH "#include \"tjsInterface.h\"\n";
process_exp_stub("../../tjs2/tjsInterface.h");

print OFH "#include \"tjsErrorDefs.h\"\n";
process_exp_stub("../../tjs2/tjsErrorDefs.h");

print OFH "#include \"tjsNative.h\"\n";
process_exp_stub("../../tjs2/tjsNative.h");

print OFH "#include \"tjsVariant.h\"\n";
process_exp_stub("../../tjs2/tjsVariant.h");

print OFH "#include \"tjsArray.h\"\n";
process_exp_stub("../../tjs2/tjsArray.h");

print OFH "#include \"tjsDictionary.h\"\n";
process_exp_stub("../../tjs2/tjsDictionary.h");

print OFH "#include \"tjs.h\"\n";
process_exp_stub("../../tjs2/tjs.h");

print OFH "#include \"tjsMessage.h\"\n";
process_exp_stub("../../tjs2/tjsMessage.h");

print OFH "#include \"tjsGlobalStringMap.h\"\n";
process_exp_stub("../../tjs2/tjsGlobalStringMap.h");

print OFH "#include \"tjsObject.h\"\n";
process_exp_stub("../../tjs2/tjsObject.h");
process_exp_stub("../../tjs2/tjsObject.cpp");

$defs_system = $defs;
$defs = '';

print OFH "#include \"StorageIntf.h\"\n";
process_exp_stub("../StorageIntf.h");

print OFH "#include \"TextStream.h\"\n";
process_exp_stub("../TextStream.h");

print OFH "#include \"CharacterSet.h\"\n";
process_exp_stub("../CharacterSet.h");

print OFH "#include \"XP3Archive.h\"\n";
process_exp_stub("../XP3Archive.h");

print OFH "#include \"EventIntf.h\"\n";
process_exp_stub("../EventIntf.h");

print OFH "#include \"SystemIntf.h\"\n";
process_exp_stub("../SystemIntf.h");

print OFH "#include \"SystemImpl.h\"\n";
process_exp_stub("./SystemImpl.h");

print OFH "#include \"ScriptMgnIntf.h\"\n";
process_exp_stub("../ScriptMgnIntf.h");

print OFH "#include \"StorageImpl.h\"\n";
process_exp_stub("../win32/StorageImpl.h");

print OFH "#include \"PluginImpl.h\"\n";
process_exp_stub("../win32/PluginImpl.h");

print OFH "#include \"SysInitIntf.h\"\n";
process_exp_stub("../SysInitIntf.h");

print OFH "#include \"SysInitImpl.h\"\n";
process_exp_stub("../win32/SysInitImpl.h");

print OFH "#include \"DetectCPU.h\"\n";
process_exp_stub("../../environ/win32/DetectCPU.h");

print OFH "#include \"ThreadIntf.h\"\n";
process_exp_stub("../../utils/ThreadIntf.h");

print OFH "#include \"DebugIntf.h\"\n";
process_exp_stub("../../utils/DebugIntf.h");

#print OFH "#include \"KAGParser.h\"\n";
#process_exp_stub("../../utils/KAGParser.h");

print OFH "#include \"Random.h\"\n";
process_exp_stub("../../utils/Random.h");

print OFH "#include \"ClipboardIntf.h\"\n";
process_exp_stub("../../utils/ClipboardIntf.h");

print OFH "#include \"TickCount.h\"\n";
process_exp_stub("../../utils/TickCount.h");

print OFH "#include \"MsgIntf.h\"\n";
process_exp_stub("../../msg/MsgIntf.h");

print OFH "#include \"WaveIntf.h\"\n";
process_exp_stub("../../sound/WaveIntf.h");

print OFH "#include \"WaveImpl.h\"\n";
process_exp_stub("../../sound/win32/WaveImpl.h");

#print OFH "#include \"MIDIImpl.h\"\n";
#process_exp_stub("../../sound/win32/MIDIImpl.h");

print OFH "#include \"GraphicsLoaderIntf.h\"\n";
process_exp_stub("../../visual/GraphicsLoaderIntf.h");

print OFH "#include \"tvpfontstruc.h\"\n";
process_exp_stub("../../visual/tvpfontstruc.h");

print OFH "#include \"tvpinputdefs.h\"\n";
process_exp_stub("../../visual/tvpinputdefs.h");

print OFH "#include \"LayerBitmapIntf.h\"\n";
process_exp_stub("../../visual/LayerBitmapIntf.h");

print OFH "#include \"drawable.h\"\n";
process_exp_stub("../../visual/drawable.h");

print OFH "#include \"ComplexRect.h\"\n";
process_exp_stub("../../visual/ComplexRect.h");

print OFH "#include \"LayerIntf.h\"\n";
process_exp_stub("../../visual/LayerIntf.h");

print OFH "#include \"LayerManager.h\"\n";
process_exp_stub("../../visual/LayerManager.h");

print OFH "#include \"WindowIntf.h\"\n";
process_exp_stub("../../visual/WindowIntf.h");

print OFH "#include \"WindowImpl.h\"\n";
process_exp_stub("../../visual/win32/WindowImpl.h");

print OFH "#include \"DrawDevice.h\"\n";
process_exp_stub("../../visual/win32/DrawDevice.h");

print OFH "#include \"voMode.h\"\n";
process_exp_stub("../../visual/voMode.h");

print OFH "#include \"VideoOvlIntf.h\"\n";
process_exp_stub("../../visual/VideoOvlIntf.h");

print OFH "#include \"TransIntf.h\"\n";
process_exp_stub("../../visual/TransIntf.h");

print OFH "#include \"transhandler.h\"\n";
process_exp_stub("../../visual/transhandler.h");

print OFH "#include \"tvpgl.h\"\n";
process_exp_stub("../../visual/tvpgl.h");

print OFH "#include \"tvpgl_ia32_intf.h\"\n";
process_exp_stub("../../visual/IA32/tvpgl_ia32_intf.h");

print OFH "#include \"TVPVideoOverlay.h\"\n";
process_exp_stub("../../movie/win32/TVPVideoOverlay.h");

$defs_misc = $defs;
$defs = '';

@all_list = (@method_list, @func_list);

print OFH <<EOF;

#include <zlib/zlib.h>
EOF

$func_data = '';
foreach $each (@all_list)
{
	@pair = split(/\t/, $each);
	$func_data .= $pair[1] . "\0";
}

$deflateout = '';

$deflateout = compress($func_data);
;# ($deflate, $status) = deflateInit( -Level => Z_BEST_COMPRESSION );
;# ($deflateout, $status) = $deflate->deflate( $func_data );
;# ($deflateout, $status) = $deflate->flush();

$emitdata = $deflateout;
$emitdata =~ s/(.)/sprintf("0x%02x, ", ord $1)/seg;
$emitdata =~ s/(.{96})/$1\n/g;
$emitdata .= "\n";
# $emitdata =~ s/(.*?), \n/\t__emit__($1);\n/sg;

print OFH <<EOF;
/* function table is pretty large; is compressed via zlib */
static tjs_uint8 compressed_functable[] = {
$emitdata
};
static void * func_ptrs[] = {
EOF

$i = 0;
foreach $each (@all_list)
{
	print OFH "\t";
	@pair = split(/\t/, $each);
	print OFH $pair[0]. ",";
	print OFH "\n";
	$i ++;
}

print OFH <<EOF;

};

EOF

print OFH <<EOF;

void TVPExportFunctions()
{
EOF


print OFH "\tconst unsigned long compressed_size = ".length($deflateout).";\n";
print OFH "\tconst unsigned long decompressed_size = ".length($func_data).";\n";
print OFH "\tconst tjs_int function_count = ".$i.";\n";

print OFH <<EOF;
	unsigned char * dest = new unsigned char [decompressed_size];

	try
	{
		unsigned long dest_size = decompressed_size;

		int result = uncompress(dest, &dest_size,
			(unsigned char*)compressed_functable, compressed_size);
		if(result != Z_OK || dest_size != decompressed_size) { TVPThrowInternalError; }

		const unsigned char *p = dest;

		for(tjs_int i = 0; i < function_count; i++)
		{
			TVPAddExportFunction((const char *)p, ((void **)func_ptrs)[i]);
			while(*p) p++;
			p++;
		}
	}
	catch(...)
	{
		delete [] dest;
		throw;
	}
	delete [] dest;
}
EOF

;# stub library for plugin

open(OHFH, ">$output_tpstub_h") or die;
open(OCFH, ">$output_tpstub_cpp") or die;

print OHFH $copyright;
print OCFH $copyright;

$func_count = $#all_list + 1;


print OCFH <<EOF;

#include <windows.h>
#include "tp_stub.h"

#define TVP_IN_PLUGIN_STUB

tjs_int TVPPluginGlobalRefCount = 0;

//---------------------------------------------------------------------------
// stubs
//---------------------------------------------------------------------------
EOF


print OHFH <<EOF;
#ifndef __TP_STUB_H__
#define __TP_STUB_H__

#ifndef __cplusplus
	#error Sorry, currently tp_stub.h can only be used in C++ mode.
#endif

#include <string>
#include <stdarg.h>

#ifndef _WIN32
	#error Sorry, currently tp_stub.h can only be used in Win32 VC++ or Borland compilers.
#endif



EOF

print OHFH $defs_system;


print OHFH <<EOF;

#ifdef __BORLANDC__
#pragma warn -8027
#endif

//---------------------------------------------------------------------------
// function import pointers
//---------------------------------------------------------------------------

extern void * TVPGetImportFuncPtr(const char *name);


EOF

foreach $each (@all_list)
{
	@pair = split(/\t/, $each);

	print OHFH "extern void * TVPImportFuncPtr".$pair[5].";\n";
}



print OHFH <<EOF;


//---------------------------------------------------------------------------
// tTJSVariantString
//---------------------------------------------------------------------------

EOF

open(FH, "../../tjs2/tjsVariantString.h") or die;
$content = <FH>;


print OHFH <<EOF;
class tTJSVariantString : protected tTJSVariantString_S
{
	// do not create an instance of this class directly.

public:
EOF

foreach $each (@variantstring)
{
	print OHFH $each."\n";
}
$content =~ /\/\*start-of-tTJSVariantString\*\/(.*?)\/\*end-of-tTJSVariantString\*\//s;
$class = $1;
while($class =~ /\/\*m\[\*\/(.*?)\/\*\]m\*\//gs)
{
	print OHFH "\t";
	print OHFH $1;
	print OHFH "\n\n";
}

print OHFH <<EOF;
};
EOF

print OHFH <<EOF;
//---------------------------------------------------------------------------
// tTJSVariantOctet
//---------------------------------------------------------------------------

EOF

open(FH, "../../tjs2/tjsVariant.h") or die;
$content = <FH>;


print OHFH <<EOF;
class tTJSVariantOctet : protected tTJSVariantOctet_S
{
	// do not create an instance of this class directly.

public:
EOF

foreach $each (@variantoctet)
{
	print OHFH $each."\n";
}

$content =~ /\/\*start-of-tTJSVariantOctet\*\/(.*?)\/\*end-of-tTJSVariantOctet\*\//s;
$class = $1;
while($class =~ /\/\*m\[\*\/(.*?)\/\*\]m\*\//gs)
{
	print OHFH "\t";
	print OHFH $1;
	print OHFH "\n\n";
}

print OHFH <<EOF;
};
EOF


print OHFH <<EOF;
//---------------------------------------------------------------------------
// tTJSVariant
//---------------------------------------------------------------------------

EOF

open(FH, "../../tjs2/tjsVariant.h") or die;
$content = <FH>;


print OHFH <<EOF;
class tTJSVariant : protected tTJSVariant_S
{

public:
EOF

foreach $each (@variant)
{
	print OHFH $each."\n";
}

$content =~ /\/\*start-of-tTJSVariant\*\/(.*?)\/\*end-of-tTJSVariant\*\//s;
$class = $1;
while($class =~ /\/\*m\[\*\/(.*?)\/\*\]m\*\//gs)
{
	print OHFH "\t";
	print OHFH $1;
	print OHFH "\n\n";
}

print OHFH <<EOF;
};
EOF

print OHFH <<EOF;
//---------------------------------------------------------------------------
// tTJSString
//---------------------------------------------------------------------------

EOF

open(FH, "../../tjs2/tjsString.h") or die;
$content = <FH>;


print OHFH <<EOF;
class tTJSString : protected tTJSString_S
{

public:
EOF

foreach $each (@string)
{
	print OHFH $each."\n";
}

$content =~ /\/\*start-of-tTJSString\*\/(.*?)\/\*end-of-tTJSString\*\//s;
$class = $1;
while($class =~ /\/\*m\[\*\/(.*?)\/\*\]m\*\//gs)
{
	print OHFH "\t";
	print OHFH $1;
	print OHFH "\n\n";
}

print OHFH <<EOF;
};
EOF

print OHFH <<EOF;

//---------------------------------------------------------------------------
// stubs (misc)
//---------------------------------------------------------------------------

EOF

print OHFH $defs_misc;


print OHFH <<EOF;
//---------------------------------------------------------------------------




//---------------------------------------------------------------------------
// stubs
//---------------------------------------------------------------------------

EOF


foreach $each (@func_list)
{
	@pair = split(/\t/, $each);
	print OHFH "inline ".$pair[3]."\n";
	print OHFH "{\n";
	print OHFH
			"\tif(!TVPImportFuncPtr".$pair[5].")\n".
			"\t{\n".
			"\t\tstatic char funcname[] = \"".$pair[1]."\";\n".
			"\t\tTVPImportFuncPtr".$pair[5]." = TVPGetImportFuncPtr(funcname);\n".
			"\t}\n";
	print OHFH "\ttypedef ".$pair[7].";\n";
	print OHFH "\t".($pair[8] eq 'void' ? '' : 'return ')."((__functype)(TVPImportFuncPtr".$pair[5]."))";
	print OHFH "(".$pair[6].");\n";
	print OHFH "}\n";
}


print OCFH <<EOF;
//---------------------------------------------------------------------------
// Stub library setup
//---------------------------------------------------------------------------

static iTVPFunctionExporter * TVPFunctionExporter = NULL;

void * TVPGetImportFuncPtr(const char *name)
{
	void *ptr;
	if(TVPFunctionExporter->QueryFunctionsByNarrowString(&name, &ptr, 1))
	{
		// succeeded
	}
	else
	{
		// failed
		static const char *funcname = "void ::TVPThrowPluginUnboundFunctionError(const char *)";
		if(!TVPFunctionExporter->QueryFunctionsByNarrowString(&funcname, &ptr, 1))
		{
			*(int*)0 = 0; // causes an error
		}
		typedef void (__stdcall * __functype)(const char *);
		((__functype)(ptr))(name);
	}
	return ptr;
}

/* TVPInitImportStub : stub initialization */
bool TVPInitImportStub(iTVPFunctionExporter * exporter)
{
	// set TVPFunctionExporter
	TVPFunctionExporter = exporter;
	return true;
}

/* TVPUninitImportStub : stub uninitialization */
void TVPUninitImportStub()
{
}



EOF


foreach $each (@all_list)
{
	@pair = split(/\t/, $each);

	print OCFH "void * TVPImportFuncPtr".$pair[5]." = NULL;\n";
}



print OCFH $impls;

print OHFH <<EOF;

#ifdef __BORLANDC__
#pragma warn .8027
#endif

//---------------------------------------------------------------------------
// Stub library setup
//---------------------------------------------------------------------------
extern bool TVPInitImportStub(iTVPFunctionExporter * exporter);
extern void TVPUninitImportStub();
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
// Global reference count
//---------------------------------------------------------------------------
extern tjs_int TVPPluginGlobalRefCount;
//---------------------------------------------------------------------------

EOF

close OCFH;
close OHFH;



;#---------------------------------------------------------------------------
;# exception protected function stub
;#---------------------------------------------------------------------------

;# currently only for iTJSDispatch2

;# read the header
open OHFH, "$output_tpstub_h" or die;
undef $/;
$oh = <OHFH>;
close OHFH;

;# extract iTJSDispatch2 declaration
die if($oh !~ /class\s+iTJSDispatch2\s+\{(.*?)\}/s);
$class_iTJSDispatch2 = $1;

;# eliminate comments
$class_iTJSDispatch2 =~ s|//.*?\n||gs;
$class_iTJSDispatch2 =~ s|/\*.*?\*/||gs;

;# extract method declarations
$hc = '';
$cc = '';

$cc .= <<EOF;

static bool TJS_USERENTRY _CatchFuncCall(void *data, const tTVPExceptionDesc & desc)
{
	throw desc;
}
EOF

while($class_iTJSDispatch2 =~
	m|virtual\s+(\w+)\s+TJS_INTF_METHOD\s+(\w+)\s*\(\s*(.*?)\s*\)|gs)
{
	$ret_type = $1;
	$method_name = $2;
	@args = split(/\s*,\s*/, $3 eq 'void' ? '' : $3);

	$hc .= 
		("extern $ret_type Try_iTJSDispatch2_$method_name(" .
			join(', ',  ("iTJSDispatch2 * _this", @args)) . ");\n");


	$cc .= "struct t_iTJSDispatch2_$method_name\n";
	$cc .= "{\n";
	if($ret_type ne 'void')
	{
		$cc .= "\t$ret_type _ret;\n";
	}

	foreach $arg ("iTJSDispatch2 * _this", @args)
	{
		$cc .= "\t$arg;\n";
	}

	@arg_names = ();
	foreach $arg (@args)
	{
		if($arg =~ /(\w+)$/)
		{
			push @arg_names, $1;
		}
	}
	$cc .= "\tt_iTJSDispatch2_$method_name(\n\t\t\t";
	$cc .= join("_,\n\t\t\t",  ("iTJSDispatch2 * _this", @args));
	$cc .= "_\n\t\t\t) :\n\t\t";
	@arg_initials = ();
	foreach $arg_name ("_this", @arg_names)
	{
		push @arg_initials, "$arg_name(${arg_name}_)";
	}

	$cc .= join(",\n\t\t", @arg_initials);
	$cc .= "\t{;}\n";

	$cc .= "\n};\n";

	$cc .= "static void TJS_USERENTRY _Try_iTJSDispatch2_$method_name(void *data)\n";
	$cc .= "{\n";
	$cc .= "	t_iTJSDispatch2_$method_name * arg = (t_iTJSDispatch2_$method_name *)data;\n";
	$cc .= "	arg->_ret = \n" if $ret_Type ne 'void';
	$cc .= "	arg->_this->$method_name(\n		";
	@arg_args = ();
	foreach $arg_name (@arg_names)
	{
		push @arg_args, "arg->$arg_name";
	}
	$cc .= join(",\n\t\t", @arg_args);
	$cc .= "\n		);\n";
	$cc .= "}\n";
	$cc .= 
		("$ret_type Try_iTJSDispatch2_$method_name(" .
			join(', ',  ("iTJSDispatch2 * _this", @args)) . ")\n");
	$cc .= "{\n";
	$cc .= "	t_iTJSDispatch2_$method_name arg(\n		";
	$cc .= join(",\n		", ("_this", @arg_names));
	$cc .= "\n	);\n";
	$cc .= "	TVPDoTryBlock(_Try_iTJSDispatch2_$method_name, _CatchFuncCall, NULL, &arg);\n";
	$cc .= "	return arg._ret;\n" if  $ret_Type ne 'void';
	$cc .= "}\n";

}


open OHFH,">>$output_tpstub_h" or die;
print OHFH <<EOF;
//---------------------------------------------------------------------------
// exception protected function stub
//---------------------------------------------------------------------------

EOF
print OHFH $hc;
print OHFH <<EOF;

#endif
EOF
close OHFH;

open OCFH,">>$output_tpstub_cpp" or die;
print OCFH <<EOF;
//---------------------------------------------------------------------------
// exception protected function stub
//---------------------------------------------------------------------------

EOF
print OCFH $cc;


;#---------------------------------------------------------------------------


