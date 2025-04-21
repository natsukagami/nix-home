{
  pkgs,
  lib,
  ...
}:
let
  dataDir = "/mnt/steam/mc/";
  javaOpts = "-Xms4096M -Xmx4096M -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=8M -XX:G1HeapWastePercent=5 -XX:G1MaxNewSizePercent=40 -XX:G1MixedGCCountTarget=4 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1NewSizePercent=30 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:MaxGCPauseMillis=200 -XX:MaxTenuringThreshold=1 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true";
  name = "paper-mc";
  socketName = "${name}.stdin";
  socket = "/run/${socketName}";

  console = pkgs.writeScriptBin "papermc-console" ''
    #!${lib.getExe pkgs.python3}
    # https://github.com/AtomicSponge/paper-systemd/blob/main/minecraft-console.py

    import curses
    import subprocess
    import threading

    def run_journalctl(win):
        process = subprocess.Popen(['journalctl', '-u', '${name}', '--follow'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        while True:
            line = process.stdout.readline()
            if not line:
                break
            win.addstr(line.decode())
            win.refresh()

    def input_commands(win):
        with open('${socket}', 'a') as f:
            while True:
                win.clear()
                win.addstr("Enter command (Ctrl-C to exit): ")
                curses.echo()
                win.move(1, 0)
                command = win.getstr().decode()
                f.write(command + "\n")
                f.flush()
                curses.noecho()
                win.clear()

    def main(stdscr):
        try:
            curses.curs_set(1)
            stdscr.clear()
            
            height, width = stdscr.getmaxyx()
            journal_height = int(height * 0.9)
            input_height = height - journal_height

            journal_win = stdscr.subwin(journal_height, width, 0, 0)
            journal_win.scrollok(True)
            input_win = stdscr.subwin(input_height, width, journal_height, 0)

            thread = threading.Thread(target=run_journalctl, args=(journal_win,))
            thread.daemon = True
            thread.start()

            input_commands(input_win)
            
        except KeyboardInterrupt:
            stdscr.clear()
            stdscr.refresh()
        finally:
            curses.endwin()

    if __name__ == "__main__":
        curses.wrapper(main)
  '';
in
{
  environment.systemPackages = [ console ];
  users.users.${name} = {
    isSystemUser = true;
    group = name;
  };
  users.users.nki.extraGroups = [ name ];
  users.groups.${name} = {
  };
  systemd.sockets.${name} = {
    partOf = [ "${name}.service" ];
    socketConfig.ListenFIFO = "%t/${socketName}";
  };
  systemd.services.${name} = {
    description = "Minecraft Server";
    serviceConfig = {
      Type = "simple";
      WorkingDirectory = dataDir;
      User = name;
      Restart = "on-failure";
      Sockets = "${name}.socket";
      StandardInput = "socket";
      StandardOutput = "journal";
      StandardError = "journal";
      ReadWritePaths = [ dataDir ];
    };
    environment.JAVA_OPTS = javaOpts;
    script = "${lib.getExe pkgs.papermc}";
    preStop = "echo stop > ${socket}";
    wantedBy = [ "multi-user.target" ];
  };
}
