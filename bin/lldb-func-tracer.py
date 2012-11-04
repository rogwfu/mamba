#!/usr/bin/env python
# Notes:
# (lldb) image list CorePDF
# [  0] B5B5215F-38C0-364D-BDA4-35D674FFCEC4 0x00007fff81cf0000 /System/Library/PrivateFrameworks/CorePDF.framework/Versions/A/CorePDF 

import sys
sys.path.append("/Applications/Xcode.app/Contents/SharedFrameworks/LLDB.framework/Resources/Python")
import lldb
import lldbutil 
import os
import optparse
import signal
from lxml import etree as ET


# Global variable for the target being debugged
target = None

# Signal handler to print statistics
# Format: <hit><funcname>auto_zone_start_monitor</funcname><offset>0x1080</offset></hit>
# Debugging: print breakpointLocation
def printBreakStats(SIG, FRM):
    global target
    root = ET.Element("fuzz.io")
    for breakpoint in target.breakpoint_iter():
        for breakpointLocation in breakpoint:
            # Hack since I can't find a GetHitCount() for a SBBreakpointLocation
            breakPointLocationInfo = str(breakpointLocation).split(",")
            blFuncName = breakPointLocationInfo[0].split("=")[1] 
            blLoadAddress = breakPointLocationInfo[1].split("=")[1] 
            blHitCount = breakPointLocationInfo[3].split("=")[1]
            blHitCount = int(blHitCount)
            if(blHitCount > 0):
              hit = ET.SubElement(root, 'hit')
              funcname = ET.SubElement(hit, "funcname")
              funcname.text = blFuncName
              offset = ET.SubElement(hit, "offset")
              offset.text = blLoadAddress
              count = ET.SubElement(hit, "count")
              count.text = str(blHitCount) 
    traceFile = open("./trace.xml", "w")
    ET.ElementTree(root).write(traceFile, pretty_print=True, xml_declaration=True) 
    exit(1)


# Catch all signals
#for i in [x for x in dir(signal) if x.startswith("SIG")]:
try:
    #signum = getattr(signal,i)
    signal.signal(signal.SIGINFO, printBreakStats)
except RuntimeError,m:
    print "Skipping %s"%i

# Look at: /Users/rseagle/Downloads/lldb/examples/python/process_events.py
def run_commands(command_interpreter, commands):
    return_obj = lldb.SBCommandReturnObject()
    for command in commands:
        command_interpreter.HandleCommand( command, return_obj )
        if return_obj.Succeeded():
            return return_obj.GetOutput()
        else:
            print return_obj
            if options.stop_on_error:
                break

def main(argv):
    description='''Records hit traces for all functions of a specific shared library'''
    epilog='''Examples:
        % ./lldb-test.py -s sharedlibrary -- /Applications/Preview.app/Contents/MacOS/Preview
            '''
    parser = optparse.OptionParser(description=description, prog='lldb-test',usage='usage: lldb-test [options] program [arg1 arg2]', epilog=epilog)
    optparse.OptionParser.format_epilog = lambda self, formatter: self.epilog
    parser.add_option('-e', '--environment', action='append', type='string', metavar='ENV', dest='env_vars', help='Environment variables to set in the inferior process when launching a process.')
    parser.add_option('-s', '--shlib', type='string', dest='shlibs', metavar='SHLIB', help='Specify the shared library to trace functions')
    parser.add_option('-t', '--event-timeout', type='int', dest='event_timeout', metavar='SEC', help='Specify the timeout in seconds to wait for process state change events.', default=lldb.UINT32_MAX)
    try:
        (options, args) = parser.parse_args(argv)
    except:
        return

    # Set the executable
    exe = args.pop(0)
    
    # Create a new debugger instance
    debugger = lldb.SBDebugger.Create()
    command_interpreter = debugger.GetCommandInterpreter()

    # Setup a target to debug
    global target
    target = debugger.CreateTargetWithFileAndArch(exe, lldb.LLDB_ARCH_DEFAULT)

    launch_info = None
    launch_info = lldb.SBLaunchInfo(args)
    if options.env_vars:
      print options.env_vars
      launch_info.SetEnvironmentEntries(options.env_vars, True)

    if target:
        error = lldb.SBError()
        # Set all the breakpoints 
        print options.shlibs
        ret = run_commands(command_interpreter, ['breakpoint set --func-regex=. --shlib=' + options.shlibs])
        # Launch the process. Since we specified synchronous mode, we won't return
        # from this function until we hit the breakpoint at main
        process = target.Launch(launch_info, error) 
        if process and process.GetProcessID() != lldb.LLDB_INVALID_PROCESS_ID:
            pid = process.GetProcessID()
            listener = lldb.SBListener("event_listener")
            # sign up for process state change events
            process.GetBroadcaster().AddListener(listener, lldb.SBProcess.eBroadcastBitStateChanged)
            done = False
            while not done:
                event = lldb.SBEvent()
                if listener.WaitForEvent(options.event_timeout, event):
                        state = lldb.SBProcess.GetStateFromEvent (event)
                        if state == lldb.eStateStopped:

                          thread = lldbutil.get_stopped_thread(process, lldb.eStopReasonBreakpoint)
                          if thread == None:
                              print "Error: No Stopped Thread"
                              # Terminate the Debugger
                              lldb.SBDebugger.Terminate()
                          else:
#                              print "Breakpoint"
                              process.Continue()
                        elif state == lldb.eStopReasonSignal:
                            print "Got a signal"
                        elif state == lldb.eStateRunning:
                            print "Running"
                        elif state == lldb.eStateExited:
                            exit_desc = process.GetExitDescription()
                            if exit_desc:
                                print "process %u exited with status %u: %s" % (pid, process.GetExitStatus (), exit_desc)
                            else:
                                print "process %u exited with status %u" % (pid, process.GetExitStatus ())
                        elif state == lldb.eStateCrashed:
                            process.Continue()
                        elif state == lldb.eStateUnloaded:
                            print "process %u unloaded, this shouldn't happen" % (pid)
                            done = True
                        elif state == lldb.eStateConnected:
                            print "process connected"
                        elif state == lldb.eStateAttaching:
                            print "process attaching"
                        elif state == lldb.eStateLaunching:
                            print "process launching"
                        else:
                            print "Stopped"
                            done = True
            # kill the process
            process.Kill() 

        # Terminate the Debugger
        lldb.SBDebugger.Terminate()
if __name__ == '__main__':
    main(sys.argv[1:])
