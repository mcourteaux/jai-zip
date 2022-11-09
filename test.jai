#import "Basic";
#import "File";

test_read :: () {
  zip := zip_open("test_zip/created.zip", 0, #char "r");
  zip_entry_openbyindex(zip, 0);
  print("entry: %\n", zip_entry_name(zip));

  buf_data: *void;
  bufsize: u64;
  zip_entry_read(zip, *buf_data, *bufsize);
  defer free(buf_data);
  buf: string;
  buf.data = buf_data;
  buf.count = xx bufsize;
  print("file:\n%\n", buf);

  zip_entry_close(zip);
  zip_close(zip);

}

test_read_as_string :: () {
  zip := zip_open("test_zip/created.zip", 0, #char "r");
  zip_entry_openbyindex(zip, 0);
  print("entry: %\n", zip_entry_name(zip));

  data := zip_entry_read(zip);
  defer free(data.data);
  print("buf.data = %, buf.count = %", data.data, data.count);
  print("file:\n%\n", data);

  zip_entry_close(zip);
  zip_close(zip);
}

test_make_zip :: () {
  make_directory_if_it_does_not_exist("test_zip");
  filenames: [2] string;
  filenames[0] = "module.jai";
  filenames[1] = "test.jai";
  status := zip_create("test_zip/created.zip", filenames);
  print("zip_create() status: %\n", status);
}

test_extract_zip :: () {
  callback :: (filename: string, arg: *void) -> s32 {
    print("Extracting '%'...\n", filename);
    return 0;
  };
  status := zip_extract("test_zip/created.zip", "test_zip/", callback, null);
  print("zip_extract() status: %\n", status);
}

main :: () {
  test_make_zip();
  test_extract_zip();
  test_read();
  test_read_as_string();
}

#scope_file

#load "module.jai";
