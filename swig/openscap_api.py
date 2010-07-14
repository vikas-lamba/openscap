# This file is a wrapper for python API for openscap
# library
#
# Copyright 2010 Red Hat Inc., Durham, North Carolina.
# All Rights Reserved.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software 
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# Authors:
#      Maros Barabas  <mbarabas@redhat.com>

DEBUG = 0

from sys import version_info
if version_info >= (2,6,0):
    def _import_helper():
        from os.path import dirname
        import imp
        fp = None
        try:
            fp, pathname, description = imp.find_module('_openscap_py', [dirname(__file__)])
        except ImportError:
            import _openscap_py as OSCAP
            return OSCAP
        if fp is not None:
            try:
                _mod = imp.load_module('_openscap_py', fp, pathname, description)
            finally:
                fp.close()
            return _mod
    OSCAP = _import_helper()
    del _import_helper
else:
    import OSCAP

del version_info

# Abstract class of OSCAP Object
class OSCAP_Object(object):

    """ Called when the instance is created """
    def __init__(self, object, instance=None):
        dict.__setattr__(self, "object", object)
        if instance != None: dict.__setattr__(self, "instance", instance)

    @staticmethod
    def new(retobj):
        if type(retobj).__name__ == 'SwigPyObject':
            #print retobj.__repr__().split("'")[1]
            if retobj.__repr__().split("'")[1].split()[0] == "struct": structure = retobj.__repr__().split("'")[1].split()[1]
            else: structure = retobj.__repr__().split("'")[1].split()[0]
            return OSCAP_Object(structure, retobj)
        else: return retobj

    def __repr__(self):
        return "<Oscap Object of type '%s' at %s>" % (self.object, hex(id(self)),)

    def __func_wrapper(self, func, value=None):

        def __getter_wrapper(*args, **kwargs):
            newargs = ()
            for arg in args:
                if isinstance(arg, OSCAP_Object):
                    newargs += (arg.instance,)
                else: newargs += (arg,)

            try:
                retobj = func()
            except TypeError as err:
                if DEBUG > 0: print "__func_wrapper::()::err_handling::%s" % (err,)
                try:
                    retobj = func(self.instance)
                except TypeError as err:
                    if DEBUG > 0: print "__func_wrapper::(1)::err_handling::%s" % (err,)
                    try:
                        retobj = func(*newargs)
                    except TypeError as err:
                        if DEBUG > 0: print "__func_wrapper::(*)::err_handling::%s" % (err,)
                        try:
                            retobj = func(self.instance, *newargs)
                        except TypeError as err:
                            if DEBUG > 0: print "__func_wrapper::(1,*)::err_handling::%s" % (err,)
                            raise TypeError("Wrong number of arguments in function %s" % (func.__name__,))

            if retobj == None: return None
            return OSCAP_Object.new(retobj)
        
        return __getter_wrapper

    """ Called when an attribute lookup has not found the attribute in the usual places (i.e. 
        it is not an instance attribute nor is it found in the class tree for self). name is 
        the attribute name.
    """
    def __getattr__(self, name):
        if DEBUG > 0: print "func::__getattr__::%s::__getattr__(%s)" % (self.object, name)
        if self.__dict__.has_key(name): 
            return self.__dict__[name]

        # If attribute is not in a local dictionary, look for it in a library
        func = OSCAP.__dict__.get(name)
        if func != None: return func

        if DEBUG > 0: print "func::__getattr__::%s::Calling library on getter %s_%s" % (self.object, self.object, name)
        obj = OSCAP.__dict__.get(self.object+"_"+name)
        if obj != None: 
            if callable(obj):
                return self.__func_wrapper(obj)

        if DEBUG > 0: print "func::__getattr__::%s::Calling library on getter %s_get_%s" % (self.object, self.object, name)
        obj = OSCAP.__dict__.get(self.object+"_get_"+name)
        if obj != None:
            try: return self.__func_wrapper(obj)()
            except: return self.__func_wrapper(obj)
        elif DEBUG > 0: print "func::__getattr__::%s::Object does not exist: %s" % (self.object, obj)

        return OSCAP_Object(self.object+"_"+name)

    def __call__(self, *args, **kwargs):
        newargs = ()
        for arg in args:
            if isinstance(arg, OSCAP_Object):
                newargs += (arg.instance,)
            else: newargs += (arg,)

        # It's maybe looking for "new" ?
        obj = OSCAP.__dict__.get(self.object+"_new")
        if obj != None:
            return OSCAP_Object.new(obj(*newargs))
        else: raise NameError("name '"+self.object+"' is not defined")

    def __setattr__(self, name, value):
        if DEBUG > 0: print "func::__setattr__::%s::__setattr__(%s)" % (self.object, name)
        if self.__dict__.has_key(name): 
            return self.__dict__[name]

        # If attribute is not in a local dictionary, look for it in a library
        #func = OSCAP.__dict__.get(name)
        #if func != None: return func

        if DEBUG > 0: print "func::__setattr__::%s::Calling library on setter %s_set_%s" % (self.object, self.object, name)
        obj = OSCAP.__dict__.get(self.object+"_set_"+name)
        if obj == None:
            if DEBUG > 0: print "func::__setattr__::%s::Calling library on setter %s_add_%s" % (self.object, self.object, name)
            obj = OSCAP.__dict__.get(self.object+"_add_"+name) 
        if obj == None: 
            if DEBUG > 0: print "func::__setattr__::%s::Setter function %s not found !" % (self.object, self.object+"_(add/set)_"+name,)
            return None
        if isinstance(value, OSCAP_Object):
                    value = value.instance
        return obj(self.instance, value)

    """ ********* Implementation of non-trivial functions ********* """

    def register_output_callback(self, cb, usr):
        if self.object != "xccdf_policy_model": raise TypeError("Wrong call of register_output_callback function on %s" % (self.object,))
        return OSCAP.xccdf_policy_model_register_output_callback_py(self.instance, cb, usr)

    def register_engine_oval(self, sess):
        if self.object != "xccdf_policy_model": raise TypeError("Wrong call of register_engine_oval function on %s" % (self.object,))
        return OSCAP.xccdf_policy_model_register_engine_oval(self.instance, sess.instance)
    
# ------------------------------------------------------------------------------------------------------------
# XCCDF

class _XCCDF_Benchmark_Class(OSCAP_Object):

    def __init__(self, path):
        #dict.__setattr__(self, "__name", "xccdf_benchmark")
        dict.__setattr__(self, "object", "xccdf_benchmark")
        dict.__setattr__(self, "instance", OSCAP.xccdf_benchmark_import(path))

    def __repr__(self):
        return "<Oscap Object of type 'XCCDF Benchmark' at %s>" % (hex(id(self)),)


class XCCDF_Class(OSCAP_Object):

    def __init__(self):
        dict.__setattr__(self, "object", "xccdf")
        dict.__setattr__(self, "version", OSCAP.xccdf_benchmark_supported())
        pass

    def __repr__(self):
        return "<Oscap Object of type 'XCCDF Class' at %s>" % (hex(id(self)),)

    """ Import XCCDF Benchmark 
    """
    def benchmark_import(self, path):
        return _XCCDF_Benchmark_Class(path)



# ------------------------------------------------------------------------------------------------------------
# OVAL

class OVAL_Class(OSCAP_Object):

    def __init__(self):
        dict.__setattr__(self, "object", "oval")
        dict.__setattr__(self, "version", OSCAP.oval_definition_model_supported())
        pass

    def __repr__(self):
        return "<Oscap Object of type 'OVAL Class' at %s>" % (hex(id(self)),)

# ------------------------------------------------------------------------------------------------------------
# CVE

class CVE_Class(OSCAP_Object):

    def __init__(self):
        dict.__setattr__(self, "object", "cve")
        dict.__setattr__(self, "version", OSCAP.cve_model_supported())
        pass

    def __repr__(self):
        return "<Oscap Object of type 'CVE Class' at %s>" % (hex(id(self)),)

# ------------------------------------------------------------------------------------------------------------
# CPE

class CPE_Class(OSCAP_Object):

    def __init__(self):
        dict.__setattr__(self, "object", "cpe")
        dict.__setattr__(self, "version", "CPE Lang: %s; CPE Dict: %s; CPE Name: %s" 
                % (OSCAP.cpe_lang_model_supported(), 
                    OSCAP.cpe_dict_model_supported(),
                    OSCAP.cpe_name_supported()))
        pass

    def __repr__(self):
        return "<Oscap Object of type 'CPE Class' at %s>" % (hex(id(self)),)

# ------------------------------------------------------------------------------------------------------------
# CVSS

class CVSS_Class(OSCAP_Object):

    def __init__(self):
        dict.__setattr__(self, "object", "cvss")
        dict.__setattr__(self, "version", OSCAP.cvss_model_supported())
        pass

    def __repr__(self):
        return "<Oscap Object of type 'CVSS Class' at %s>" % (hex(id(self)),)

# ------------------------------------------------------------------------------------------------------------
# CCE

class CCE_Class(OSCAP_Object):

    def __init__(self):
        dict.__setattr__(self, "object", "cce")
        dict.__setattr__(self, "version", OSCAP.cce_supported())
        pass

    def __repr__(self):
        return "<Oscap Object of type 'CCE Class' at %s>" % (hex(id(self)),)

# ------------------------------------------------------------------------------------------------------------

xccdf = XCCDF_Class()
oval  = OVAL_Class()
cve   = CVE_Class()
cce   = CCE_Class()
cpe   = CPE_Class()
cvss  = CVSS_Class()
oscap = OSCAP_Object("oscap")
