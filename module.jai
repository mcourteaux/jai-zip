ZIP_DEFAULT_COMPRESSION_LEVEL :: 6;

using zip_err :: enum c_int {
  ZIP_ENOINIT :: -1      ; // not initialized
  ZIP_EINVENTNAME :: -2  ; // invalid entry name
  ZIP_ENOENT :: -3       ; // entry not found
  ZIP_EINVMODE :: -4     ; // invalid zip mode
  ZIP_EINVLVL :: -5      ; // invalid compression level
  ZIP_ENOSUP64 :: -6     ; // no zip 64 support
  ZIP_EMEMSET :: -7      ; // memset error
  ZIP_EWRTENT :: -8      ; // cannot write data to entry
  ZIP_ETDEFLINIT :: -9   ; // cannot initialize tdefl compressor
  ZIP_EINVIDX :: -10     ; // invalid index
  ZIP_ENOHDR :: -11      ; // header not found
  ZIP_ETDEFLBUF :: -12   ; // cannot flush tdefl buffer
  ZIP_ECRTHDR :: -13     ; // cannot create entry header
  ZIP_EWRTHDR :: -14     ; // cannot write entry header
  ZIP_EWRTDIR :: -15     ; // cannot write to central dir
  ZIP_EOPNFILE :: -16    ; // cannot open file
  ZIP_EINVENTTYPE :: -17 ; // invalid entry type
  ZIP_EMEMNOALLOC :: -18 ; // extracting data using no memory allocation
  ZIP_ENOFILE :: -19     ; // file not found
  ZIP_ENOPERM :: -20     ; // no permission
  ZIP_EOOMEM :: -21      ; // out of memory
  ZIP_EINVZIPNAME :: -22 ; // invalid zip archive name
  ZIP_EMKDIR :: -23      ; // make dir error
  ZIP_ESYMLINK :: -24    ; // symlink error
  ZIP_ECLSZIP :: -25     ; // close archive error
  ZIP_ECAPSIZE :: -26    ; // capacity size too small
  ZIP_EFSEEK :: -27      ; // fseek error
  ZIP_EFREAD :: -28      ; // fread error
  ZIP_EFWRITE :: -29     ; // fwrite error
}


zip_t :: #type,distinct *void;

zip_strerror :: (errnum: zip_err) -> string {
  _zip_strerror :: (err: c_int) -> *u8 #foreign ZIP "zip_strerror";
  return to_string(_zip_strerror(xx errnum));
}

zip_open :: (zipname: string, level: c_int = ZIP_DEFAULT_COMPRESSION_LEVEL, mode: u8) -> zip_t {
  _zip_open :: (zipname: *u8, level: c_int = ZIP_DEFAULT_COMPRESSION_LEVEL, mode: u8) -> zip_t #foreign ZIP "zip_open";
  return _zip_open(zipname.data, level, mode);
}
zip_close :: (zip: zip_t) #foreign ZIP;
zip_is64 :: (zip: zip_t) -> c_int #foreign ZIP;

// Entry functions

zip_entry_open :: (zip: zip_t, entryname: string) -> c_int {
  _zip_entry_open :: (zip: zip_t, entryname: *u8) -> c_int #foreign ZIP "zip_entry_open";
  return _zip_entry_open(zip, entryname.data);
}
zip_entry_opencasesensitive :: (zip: zip_t, entryname: string) -> c_int {
  _zip_entry_opencasesensitive :: (zip: zip_t, entryname: *u8) -> c_int #foreign ZIP "zip_entry_opencasesensitive";
  return _zip_entry_opencasesensitive(zip, entryname.data);
}
zip_entry_openbyindex :: (zip: zip_t, index: c_size_t) -> c_int #foreign ZIP;
zip_entry_close :: (zip: zip_t) -> c_int #foreign ZIP;

zip_entry_name :: (zip: zip_t) -> string {
  _zip_entry_name :: (zip: zip_t) -> *u8 #foreign ZIP "zip_entry_name";
  str: *u8 = _zip_entry_name(zip);
  return to_string(str);
}

zip_entry_index :: (zip: zip_t) -> c_ssize_t #foreign ZIP;
zip_entry_isdir :: (zip: zip_t) -> c_int #foreign ZIP;
zip_entry_size :: (zip: zip_t) -> u64 #foreign ZIP;
zip_entry_uncomp_size :: (zip: zip_t) -> u64 #foreign ZIP;
zip_entry_comp_size :: (zip: zip_t) -> u64 #foreign ZIP;
zip_entry_crc32 :: (zip: zip_t) -> u32 #foreign ZIP;

zip_entry_write :: (zip: zip_t, buf: *u8, bufsize: c_size_t) -> c_int #foreign ZIP;
zip_entry_fwrite :: (zip: zip_t, filename: string) -> c_int {
  _zip_entry_fwrite :: (zip: zip_t, filename: *u8) -> c_int #foreign ZIP "zip_entry_fwrite";
  return _zip_entry_fwrite(zip, filename.data);
}

zip_entry_read :: (zip: zip_t, buf: **void, bufsize: *c_size_t) -> c_ssize_t #foreign ZIP;
zip_entry_noallocread :: (zip: zip_t, buf: *void, bufsize: c_size_t) -> c_ssize_t #foreign ZIP;

zip_entry_fread :: (zip: zip_t, filename: string) -> c_int {
  _zip_entry_fread :: (zip: zip_t, filename: *u8) -> c_int #foreign ZIP "zip_entry_fread";
  return _zip_entry_fread(zip, filename.data);
}

zip_entry_extract :: (
  zip: zip_t,
  on_extract: (arg: *void, offset: c_size_t, data: *void, size: c_size_t) -> c_size_t #c_call,
  arg: *void) #foreign ZIP;

zip_entries_total :: (zip: zip_t) -> c_ssize_t #foreign ZIP;

zip_entries_delete :: (zip: zip_t, entries: []string) -> c_size_t {
  _zip_entries_delete :: (zip: zip_t, entries: **u8, size: c_size_t) -> c_ssize_t #foreign ZIP "zip_entries_delete";
  u8_ptr_array: **u8 = xx temporary_alloc(size_of(*u8) * entries.count);
  for entries {
    u8_ptr_array[it_index] = it.data;
  }
  return xx _zip_entries_delete(zip, u8_ptr_array, xx entries.count);
}

// Stream functions

zip_stream_extract :: (stream: *u8, size: c_size_t, dir: string,
                       on_extract: (filename: string, arg: *void),
                       arg: *void) -> c_int #expand {
  _zip_stream_extract :: (stream: *u8, size: c_size_t, dir: *u8,
                          on_extract: (filename: *u8, arg: *void) #c_call,
                          arg: *void) -> c_int #foreign ZIP "zip_stream_extract";

  return _zip_stream_extract(zip, stream, size, dir.data, (filename: *u8, arg: *void) #c_call {
    new_context: Context;
    push_context new_context {
      filename_jai := to_string(filename);
      on_extract(filename_jai, arg);
    }
  }, arg);
}

zip_stream_open :: (stream: *u8, size: c_size_t, level: c_int, mode: u8) -> zip_t #foreign ZIP;
zip_stream_copy :: (zip: zip_t, buf: **u8, bufsize: *c_size_t) -> c_ssize_t #foreign ZIP;
zip_stream_close :: (zip: zip_t) -> c_ssize_t #foreign ZIP;

// All-in-one utility functions.

zip_create :: (zip_name: string, filenames: []string) -> c_int {
  _zip_create :: (zipname: *u8, filenames: **u8, len: c_size_t) -> c_int #foreign ZIP "zip_create";
  u8_ptr_array: **u8 = xx temporary_alloc(size_of(*u8) * filenames.count);
  for filenames {
    u8_ptr_array[it_index] = it.data;
  }
  return _zip_create(zip_name.data, u8_ptr_array, xx filenames.count);
}

zip_extract :: (zip_name: string, dir: string,
                on_extract: (filename: string, arg: *void) -> c_int,
                arg: *void) -> c_int #expand {
  _zip_extract :: (zipname: *u8, dir: *u8,
                   on_extract: (filename: *u8, arg: *void) -> c_int #c_call,
                   arg: *void) -> c_int #foreign ZIP "zip_extract";

  return _zip_extract(zip_name.data, dir.data, (filename: *u8, arg: *void) -> c_int #c_call {
    new_context: Context;
    push_context new_context {
      filename_jai := to_string(filename);
      return on_extract(filename_jai, arg);
    }
  }, arg);
}

// Fake expose c_free as a way to free stuff that this C-library internally has allocated.
zip_free :: inline (ptr: *void) {
  c_free(ptr);
}

#scope_file

#if OS == .LINUX {
  ZIP :: #foreign_library,no_dll "linux/libzip";
} else #if OS == .WINDOWS {
  ZIP :: #foreign_library,no_dll "windows/libzip";
} else #if OS == .MACOS {
  ZIP :: #foreign_library,no_dll "macos/libzip";
}

c_free :: (ptr: *void) #runtime_support #no_context;

#scope_module

#if size_of(*void) == 4 {
  c_ssize_t :: s32;
  c_int :: s32;
  c_size_t :: u32;
} else #if size_of(*void) == 8 {
  c_ssize_t :: s64;
  c_int :: s32;
  c_size_t :: u64;
} else {
  #assert false;
}
