{ config, ... }:

{
  environment.etc."testfile".text = if config.os.t.e.s.t.b then "true\n" else "false\n";
}
