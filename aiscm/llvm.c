// AIscm - Guile extension for numerical arrays and tensors.
// Copyright (C) 2013, 2014, 2015, 2016, 2017 Jan Wedekind <jan@wedesoft.de>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
#include <libguile.h>
#include <llvm-c/Analysis.h>
#include <llvm-c/Core.h>
#include <llvm-c/ExecutionEngine.h>
#include <llvm-c/Target.h>
#include "util-helpers.h"


static scm_t_bits llvm_module_tag;

static scm_t_bits llvm_function_tag;

static scm_t_bits llvm_value_tag;

struct llvm_module_t {
  LLVMModuleRef module;
  LLVMExecutionEngineRef engine;
};

struct llvm_function_t {
  LLVMBuilderRef builder;
  LLVMValueRef function;
};

struct llvm_value_t {
  LLVMValueRef value;
};

static struct llvm_module_t *get_llvm_no_check(SCM scm_self)
{
  return (struct llvm_module_t *)SCM_SMOB_DATA(scm_self);
}

static struct llvm_module_t *get_llvm(SCM scm_self)
{
  scm_assert_smob_type(llvm_module_tag, scm_self);
  return get_llvm_no_check(scm_self);
}

static struct llvm_function_t *get_llvm_function_no_check(SCM scm_self)
{
  return (struct llvm_function_t *)SCM_SMOB_DATA(scm_self);
}

static struct llvm_function_t *get_llvm_function(SCM scm_self)
{
  scm_assert_smob_type(llvm_function_tag, scm_self);
  return get_llvm_function_no_check(scm_self);
}

static struct llvm_value_t *get_llvm_value_no_check(SCM scm_self)
{
  return (struct llvm_value_t *)SCM_SMOB_DATA(scm_self);
}

static struct llvm_value_t *get_llvm_value(SCM scm_self)
{
  scm_assert_smob_type(llvm_value_tag, scm_self);
  return get_llvm_value_no_check(scm_self);
}

SCM llvm_module_destroy(SCM scm_self);

size_t free_llvm_module(SCM scm_self)
{
  struct llvm_module_t *self = get_llvm_no_check(scm_self);
  llvm_module_destroy(scm_self);
  scm_gc_free(self, sizeof(struct llvm_module_t), "llvm");
  return 0;
}

SCM llvm_function_destroy(SCM scm_self);

size_t free_llvm_function(SCM scm_self)
{
  struct llvm_function_t *self = get_llvm_function_no_check(scm_self);
  llvm_function_destroy(scm_self);
  scm_gc_free(self, sizeof(struct llvm_function_t), "function");
  return 0;
}

static LLVMTypeRef llvm_type(int type)
{
  switch (type) {
    case SCM_FOREIGN_TYPE_FLOAT:
      return LLVMFloatType();
    case SCM_FOREIGN_TYPE_DOUBLE:
      return LLVMDoubleType();
    case SCM_FOREIGN_TYPE_UINT8:
    case SCM_FOREIGN_TYPE_INT8:
      return LLVMInt8Type();
    case SCM_FOREIGN_TYPE_UINT16:
    case SCM_FOREIGN_TYPE_INT16:
      return LLVMInt16Type();
    case SCM_FOREIGN_TYPE_UINT32:
    case SCM_FOREIGN_TYPE_INT32:
      return LLVMInt32Type();
    case SCM_FOREIGN_TYPE_UINT64:
    case SCM_FOREIGN_TYPE_INT64:
      return LLVMInt64Type();
    default:
      return LLVMVoidType();
  };
}

static int llvm_type_to_foreign_type(LLVMTypeRef type)
{
  LLVMDumpType(type);
  switch (LLVMGetTypeKind(type)) {
    case LLVMFloatTypeKind:
      return SCM_FOREIGN_TYPE_FLOAT;
    case LLVMDoubleTypeKind:
      return SCM_FOREIGN_TYPE_DOUBLE;
    case LLVMIntegerTypeKind:
      switch (LLVMGetIntTypeWidth(type)) {
        case 8:
          return SCM_FOREIGN_TYPE_INT8;
        case 16:
          return SCM_FOREIGN_TYPE_INT16;
        case 32:
          return SCM_FOREIGN_TYPE_INT32;
        case 64:
          return SCM_FOREIGN_TYPE_INT64;
        default:
          return SCM_FOREIGN_TYPE_VOID;
      };
    default:
      return SCM_FOREIGN_TYPE_VOID;
  };
}

static LLVMValueRef scm_to_llvm_value(int type, SCM scm_value)
{
  switch (type) {
    case SCM_FOREIGN_TYPE_FLOAT:
    case SCM_FOREIGN_TYPE_DOUBLE:
      return LLVMConstReal(llvm_type(type), scm_to_double(scm_value));
    case SCM_FOREIGN_TYPE_UINT8:
    case SCM_FOREIGN_TYPE_UINT16:
    case SCM_FOREIGN_TYPE_UINT32:
    case SCM_FOREIGN_TYPE_UINT64:
      return LLVMConstInt(llvm_type(type), scm_to_uint64(scm_value), 0);
    case SCM_FOREIGN_TYPE_INT8:
    case SCM_FOREIGN_TYPE_INT16:
    case SCM_FOREIGN_TYPE_INT32:
    case SCM_FOREIGN_TYPE_INT64:
      return LLVMConstInt(llvm_type(type), scm_to_int64(scm_value), 1);
    default:
      return NULL;
  };
}

SCM make_llvm_module(void)
{
  SCM retval;
  struct llvm_module_t *self;
  self = (struct llvm_module_t *)scm_gc_calloc(sizeof(struct llvm_module_t), "llvm");
  SCM_NEWSMOB(retval, llvm_module_tag, self);
  self->module = LLVMModuleCreateWithName("aiscm");
  return retval;
}

SCM llvm_module_destroy(SCM scm_self)
{
  struct llvm_module_t *self = get_llvm_no_check(scm_self);
  if (self->engine) {
    if (self->module) {
      char *error = NULL;
      LLVMRemoveModule(self->engine, self->module, &self->module, &error);
      if (error) LLVMDisposeMessage(error);
    };
    LLVMDisposeExecutionEngine(self->engine);
    self->engine = NULL;
  };
  if (self->module) {
    LLVMDisposeModule(self->module);
    self->module = NULL;
  };
  return SCM_UNSPECIFIED;
}

SCM llvm_dump_module(SCM scm_self)
{
  struct llvm_module_t *self = get_llvm(scm_self);
  LLVMDumpModule(self->module);
  return SCM_UNSPECIFIED;
}

SCM make_llvm_function(SCM scm_llvm, SCM scm_return_type, SCM scm_name, SCM scm_argument_types)
{
  SCM retval;
  struct llvm_module_t *llvm = get_llvm(scm_llvm);
  struct llvm_function_t *self;
  self = (struct llvm_function_t *)scm_gc_calloc(sizeof(struct llvm_function_t), "llvmfunction");
  SCM_NEWSMOB(retval, llvm_function_tag, self);
  int n_arguments = scm_ilength(scm_argument_types);
  LLVMTypeRef *parameters = scm_gc_malloc_pointerless(n_arguments * sizeof(LLVMTypeRef), "make-llvm-function");
  for (int i=0; i<n_arguments; i++)
    parameters[i] = llvm_type(scm_to_int(scm_car(scm_argument_types)));
  self->builder = LLVMCreateBuilder();
  self->function = LLVMAddFunction(llvm->module,
                                   scm_to_locale_string(scm_name),
                                   LLVMFunctionType(llvm_type(scm_to_int(scm_return_type)),
                                                    parameters, n_arguments, 0));
  LLVMSetFunctionCallConv(self->function, LLVMCCallConv);
  LLVMBasicBlockRef entry = LLVMAppendBasicBlock(self->function, "entry");
  LLVMPositionBuilderAtEnd(self->builder, entry);
  return retval;
}

SCM llvm_function_destroy(SCM scm_self)
{
  struct llvm_function_t *self = get_llvm_function_no_check(scm_self);
  if (self->builder) {
    LLVMDisposeBuilder(self->builder);
    self->builder = NULL;
  };
  return SCM_UNSPECIFIED;
}

SCM llvm_function_return(SCM scm_self, SCM scm_value)
{
  struct llvm_function_t *self = get_llvm_function(scm_self);
  struct llvm_value_t *value = get_llvm_value(scm_value);
  LLVMBuildRet(self->builder, value->value);
  return SCM_UNSPECIFIED;
}

SCM llvm_function_return_void(SCM scm_self)
{
  struct llvm_function_t *self = get_llvm_function(scm_self);
  LLVMBuildRetVoid(self->builder);
  return SCM_UNSPECIFIED;
}

SCM llvm_compile_module(SCM scm_llvm, SCM scm_name)
{
  struct llvm_module_t *self = get_llvm(scm_llvm);
  if (self->engine != NULL)
    scm_misc_error("llvm-compile", "LLVM module already compiled", SCM_EOL);
  char *error = NULL;
  if (LLVMCreateJITCompilerForModule(&self->engine, self->module, 2, &error)) {
    SCM scm_error = scm_from_locale_string(error);
    LLVMDisposeMessage(error);
    scm_misc_error("llvm-compile", "Error initialising JIT engine: ~a", scm_list_1(scm_error));
  };
  return SCM_UNSPECIFIED;
}

SCM llvm_get_function_address(SCM scm_llvm, SCM scm_name)
{
  struct llvm_module_t *self = get_llvm(scm_llvm);
  return scm_from_pointer((void *)LLVMGetFunctionAddress(self->engine, scm_to_locale_string(scm_name)), NULL);
}

SCM llvm_verify_module(SCM scm_llvm)
{
  struct llvm_module_t *llvm = get_llvm(scm_llvm);
  char *error = NULL;
  if (LLVMVerifyModule(llvm->module, LLVMPrintMessageAction, &error)) {
    SCM scm_error = scm_from_locale_string(error);
    LLVMDisposeMessage(error);
    scm_misc_error("verify-module", "Module is not valid: ~a", scm_list_1(scm_error));
  };
  return SCM_UNSPECIFIED;
}

SCM make_llvm_constant(SCM scm_type, SCM scm_value)
{
  SCM retval;
  struct llvm_value_t *self;
  self = (struct llvm_value_t *)scm_gc_calloc(sizeof(struct llvm_value_t), "llvmvalue");
  SCM_NEWSMOB(retval, llvm_value_tag, self);
  int type = scm_to_int(scm_type);
  self->value = scm_to_llvm_value(type, scm_value);
  return retval;
}

SCM llvm_get_type(SCM scm_self)
{
  struct llvm_value_t *self = get_llvm_value(scm_self);
  return scm_from_int(llvm_type_to_foreign_type(LLVMTypeOf(self->value)));
}

SCM llvm_build_load(SCM scm_function, SCM scm_type, SCM scm_address)
{
  SCM retval;
  struct llvm_function_t *function = get_llvm_function(scm_function);
  struct llvm_value_t *result = (struct llvm_value_t *)scm_gc_calloc(sizeof(struct llvm_value_t), "llvmvalue");
  SCM_NEWSMOB(retval, llvm_value_tag, result);
  struct llvm_value_t *address = get_llvm_value(scm_address);
  int type = scm_to_int(scm_type);
  LLVMValueRef pointer = LLVMConstIntToPtr(address->value, LLVMPointerType(llvm_type(type), 0));
  result->value = LLVMBuildLoad(function->builder, pointer, "");
  return retval;
}

SCM llvm_build_store(SCM scm_function, SCM scm_type, SCM scm_value, SCM scm_address)
{
  struct llvm_function_t *function = get_llvm_function(scm_function);
  struct llvm_value_t *value = get_llvm_value(scm_value);
  struct llvm_value_t *address = get_llvm_value(scm_address);
  int type = scm_to_int(scm_type);
  LLVMValueRef pointer = LLVMConstIntToPtr(address->value, LLVMPointerType(llvm_type(type), 0));
  LLVMBuildStore(function->builder, value->value, pointer);
  return SCM_UNSPECIFIED;
}

SCM llvm_get_param(SCM scm_function, SCM scm_index)
{
  SCM retval;
  struct llvm_function_t *function = get_llvm_function(scm_function);
  int index = scm_to_int(scm_index);
  struct llvm_value_t *result = (struct llvm_value_t *)scm_gc_calloc(sizeof(struct llvm_value_t), "llvmvalue");
  SCM_NEWSMOB(retval, llvm_value_tag, result);
  result->value = LLVMGetParam(function->function, index);
  return retval;
}

SCM llvm_build_add(SCM scm_function, SCM scm_value_a, SCM scm_value_b)
{
  SCM retval;
  struct llvm_function_t *function = get_llvm_function(scm_function);
  struct llvm_value_t *value_a = get_llvm_value(scm_value_a);
  struct llvm_value_t *value_b = get_llvm_value(scm_value_b);
  struct llvm_value_t *result = (struct llvm_value_t *)scm_gc_calloc(sizeof(struct llvm_value_t), "llvmvalue");
  SCM_NEWSMOB(retval, llvm_value_tag, result);
  result->value = LLVMBuildAdd(function->builder, value_a->value, value_b->value, "");
  return retval;
}

SCM llvm_build_fadd(SCM scm_function, SCM scm_value_a, SCM scm_value_b)
{
  SCM retval;
  struct llvm_function_t *function = get_llvm_function(scm_function);
  struct llvm_value_t *value_a = get_llvm_value(scm_value_a);
  struct llvm_value_t *value_b = get_llvm_value(scm_value_b);
  struct llvm_value_t *result = (struct llvm_value_t *)scm_gc_calloc(sizeof(struct llvm_value_t), "llvmvalue");
  SCM_NEWSMOB(retval, llvm_value_tag, result);
  result->value = LLVMBuildFAdd(function->builder, value_a->value, value_b->value, "");
  return retval;
}

void init_llvm(void)
{
  LLVMLinkInMCJIT();
  LLVMInitializeNativeTarget();
  LLVMInitializeNativeAsmPrinter();
  LLVMInitializeNativeAsmParser();

  llvm_module_tag = scm_make_smob_type("llvmmodule", sizeof(struct llvm_module_t));
  scm_set_smob_free(llvm_module_tag, free_llvm_module);

  llvm_function_tag = scm_make_smob_type("llvmfunction", sizeof(struct llvm_function_t));
  scm_set_smob_free(llvm_function_tag, free_llvm_function);

  llvm_value_tag = scm_make_smob_type("llvmvalue", sizeof(struct llvm_value_t));

  scm_c_define_gsubr("make-llvm-module"         , 0, 0, 0, SCM_FUNC(make_llvm_module         ));
  scm_c_define_gsubr("llvm-module-destroy"      , 1, 0, 0, SCM_FUNC(llvm_module_destroy      ));
  scm_c_define_gsubr("llvm-dump-module"         , 1, 0, 0, SCM_FUNC(llvm_dump_module         ));
  scm_c_define_gsubr("make-llvm-function"       , 4, 0, 0, SCM_FUNC(make_llvm_function       ));
  scm_c_define_gsubr("llvm-function-destroy"    , 1, 0, 0, SCM_FUNC(llvm_function_destroy    ));
  scm_c_define_gsubr("llvm-function-return"     , 2, 0, 0, SCM_FUNC(llvm_function_return     ));
  scm_c_define_gsubr("llvm-function-return-void", 1, 0, 0, SCM_FUNC(llvm_function_return_void));
  scm_c_define_gsubr("llvm-compile-module"      , 1, 0, 0, SCM_FUNC(llvm_compile_module      ));
  scm_c_define_gsubr("llvm-get-function-address", 2, 0, 0, SCM_FUNC(llvm_get_function_address));
  scm_c_define_gsubr("llvm-verify-module"       , 1, 0, 0, SCM_FUNC(llvm_verify_module       ));
  scm_c_define_gsubr("make-llvm-constant"       , 2, 0, 0, SCM_FUNC(make_llvm_constant       ));
  scm_c_define_gsubr("llvm-get-type"            , 1, 0, 0, SCM_FUNC(llvm_get_type            ));
  scm_c_define_gsubr("llvm-build-load"          , 3, 0, 0, SCM_FUNC(llvm_build_load          ));
  scm_c_define_gsubr("llvm-build-store"         , 4, 0, 0, SCM_FUNC(llvm_build_store         ));
  scm_c_define_gsubr("llvm-get-param"           , 2, 0, 0, SCM_FUNC(llvm_get_param           ));
  scm_c_define_gsubr("llvm-build-add"           , 3, 0, 0, SCM_FUNC(llvm_build_add           ));
  scm_c_define_gsubr("llvm-build-fadd"          , 3, 0, 0, SCM_FUNC(llvm_build_fadd          ));
}
