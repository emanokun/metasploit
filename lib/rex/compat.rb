require 'dl'

module Rex

###
#
# This class provides os-specific functionality
#
###
module Compat

STD_INPUT_HANDLE = -10
ENABLE_LINE_INPUT = 2
ENABLE_ECHO_INPUT = 4
ENABLE_PROCESSED_INPUT = 1

def self.win32_stdin_unblock
	begin
		@@k32 ||= DL.dlopen("kernel32.dll")
		gsh = @@k32['GetStdHandle', 'LL']
		gcm = @@k32['GetConsoleMode', 'LLP']
		scm = @@k32['SetConsoleMode', 'LLL']
		
		inp = gsh.call(STD_INPUT_HANDLE)[0]
		inf = DL.malloc(DL.sizeof('L'))
		gcm.call(inp, inf)
		old_mode = inf.to_a('L', 1)[0]
		new_mode = old_mode & ~(ENABLE_LINE_INPUT|ENABLE_ECHO_INPUT|ENABLE_PROCESSED_INPUT)
		scm.call(inp, new_mode)
		
	rescue ::Exception
		raise $!
	end
end

def self.win32_stdin_block
	begin
		@@k32 ||= DL.dlopen("kernel32.dll")
		gsh = @@k32['GetStdHandle', 'LL']
		gcm = @@k32['GetConsoleMode', 'LLP']
		scm = @@k32['SetConsoleMode', 'LLL']
		
		inp = gsh.call(STD_INPUT_HANDLE)[0]
		inf = DL.malloc(DL.sizeof('L'))
		gcm.call(inp, inf)
		old_mode = inf.to_a('L', 1)[0]
		new_mode = old_mode | ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT | ENABLE_PROCESSED_INPUT
		scm.call(inp, new_mode)
		
	rescue ::Exception
		raise $!	
	end
end

def self.win32_ruby_path
	begin
		@@k32 ||= DL.dlopen("kernel32.dll")
		gmh = @@k32['GetModuleHandle', 'LP']
		gmf = @@k32['GetModuleFileName', 'LLPL']
		
		mod = gmh.call(nil)[0]
		inf = DL.malloc(1024)
		
		gmf.call(mod, inf, 1024)
		return inf.to_s
		
	rescue ::Exception
		raise $!	
	end
end

def self.win32_winexec(cmd)
	begin
		@@k32 ||= DL.dlopen("kernel32.dll")
		win = @@k32['WinExec', 'LPL']
		win.call(cmd.to_ptr, 0)
	rescue ::Exception
		raise $!	
	end
end

def self.win32_readline_daemon
	serv = nil
	port = 1024

	while (! serv and port < 65535)
		begin 
			serv = TCPServer.new('127.0.0.1', (port += 1))
		rescue ::Exception
		end
	end
	
	path = win32_ruby_path()
	rubyw = File.join(File.dirname(path.to_s), "ruby.exe")
	helpr = File.join(File.dirname(__FILE__), 'win32_stdio.rb')
	
	win32_winexec( [rubyw, helpr, port.to_s].join(" ") )
	
	# Accept the forked child
	clnt = serv.accept

	# Shutdown the server
	serv.close
	
	# Replace stdin with the socket
	$stdin.close
	$stdin = clnt
	
	# Integrate with patched readline extension
	$READLINE_STDIN = clnt
end

end
end
	
