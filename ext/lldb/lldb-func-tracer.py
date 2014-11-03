#!/usr/bin/env python
# Notes:
# (lldb) image list CorePDF
# [  0] B5B5215F-38C0-364D-BDA4-35D674FFCEC4 0x00007fff81cf0000 /System/Library/PrivateFrameworks/CorePDF.framework/Versions/A/CorePDF 

import sys
#sys.path.append("/Applications/Xcode.app/Contents/SharedFrameworks/LLDB.framework/Resources/Python")
import lldb
import lldbutil 
import os
import optparse
import signal
import numpy as np
from lxml import etree as ET

# Global variable for the target being debugged
target = None
xmlTrace = None

# Signal handler to print statistics
# Format: <hit><funcname>auto_zone_start_monitor</funcname><offset>0x1080</offset></hit>
# Debugging: print breakpointLocation
def printBreakStats(SIG, FRM):
    global target
    global xmlTrace

    root = ET.Element("fuzz.io")
    for breakpoint in target.breakpoint_iter():
        for breakpointLocation in breakpoint:
            # Hack since I can't find a GetHitCount() for a SBBreakpointLocation
            breakPointLocationInfo = str(breakpointLocation).split(",")
            blFuncName = breakPointLocationInfo[0].split("=")[1] 
            blLoadAddress = hex(breakpointLocation.GetAddress().GetFileAddress())
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
    traceFile = open(xmlTrace, "w")
    ET.ElementTree(root).write(traceFile, pretty_print=True, xml_declaration=True) 


# Catch SIGTERM signal to initiate printing stats 
try:
    signal.signal(signal.SIGTERM, printBreakStats)
except RuntimeError,m:
    print "Got an execption setting the SIGSTOP handler"

# Run commands using the lldb command line
def run_commands(command_interpreter, commands, options):
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
        % ./lldb-test.py -x lldbtrace.xml -s sharedlibrary -- /Applications/Preview.app/Contents/MacOS/Preview
            '''
    parser = optparse.OptionParser(description=description, prog='lldb-func-tracer.py',usage='usage: lldb-func-tracer.py [options] -- program [arg1 arg2]', epilog=epilog)
    optparse.OptionParser.format_epilog = lambda self, formatter: self.epilog
    parser.add_option('-e', '--environment', action='append', type='string', metavar='ENV', dest='env_vars', help='Environment variables to set in the inferior process when launching a process.')
    parser.add_option('-s', '--shlib', type='string', dest='shlibs', metavar='SHLIB', help='Specify the shared library to trace functions')
    parser.add_option('-t', '--event-timeout', type='int', dest='event_timeout', metavar='SEC', help='Specify the timeout in seconds to wait for process state change events.', default=lldb.UINT32_MAX)
    parser.add_option('-x', '--xmlfile', type='string', dest='xmlfile', metavar='XML', help='Specify an XML file to write lldb traces')
    try:
        (options, args) = parser.parse_args(argv)
    except:
        return

    # Set the executable
    exe = args.pop(0)

    # Create a new debugger instance
    debugger = lldb.SBDebugger.Create()
    command_interpreter = debugger.GetCommandInterpreter()

    launch_info = None
    launch_info = lldb.SBLaunchInfo(args)
    if options.env_vars:
        launch_info.SetEnvironmentEntries(options.env_vars, True)

    # Setup a target to debug
    global target
    global xmlTrace
    xmlTrace = options.xmlfile
    target = debugger.CreateTargetWithFileAndArch(exe, lldb.LLDB_ARCH_DEFAULT)
    if target:
        error = lldb.SBError()
        lib_breakpoints = target.BreakpointCreateByRegex(".", options.shlibs)	

        process = target.Launch(launch_info, error) 
        if process and process.GetProcessID() != lldb.LLDB_INVALID_PROCESS_ID:
            state = process.GetState ()
            pid = process.GetProcessID()
            listener = lldb.SBListener("event_listener")

            # sign up for process state change events
            process.GetBroadcaster().AddListener(listener, lldb.SBProcess.eBroadcastBitStateChanged)
            stop_idx = 0
            done = False
            while not done:
                event = lldb.SBEvent()
                if listener.WaitForEvent(options.event_timeout, event):
                        state = lldb.SBProcess.GetStateFromEvent (event)
                        if state == lldb.eStateStopped:
                            thread = lldbutil.get_stopped_thread(process, lldb.eStopReasonBreakpoint)
                            if thread == None:
                                print "Error: No Stopped Thread"
                                process.Continue()
                                exit(1)
                            else:
                                process.Continue()
                        elif state == lldb.eStopReasonSignal:
                            next
                        elif state == lldb.eStateRunning:
                            next
                        elif state == lldb.eStateExited:
                            done = True
                            exit_desc = process.GetExitDescription()
                            printBreakStats(None, None)
                            if exit_desc:
                                print "process %u exited with status %u: %s" % (pid, process.GetExitStatus (), exit_desc)
                            else:
                                print "process %u exited with status %u" % (pid, process.GetExitStatus ())
                        elif state == lldb.eStateCrashed:
                            process.Continue()
                        elif state == lldb.eStateUnloaded:
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

# Got To know functions

#triple = "x86_64-apple-macosx"
#module = target.AddModule ("/usr/lib/system/libsystem_c.dylib", triple, None, "/build/server/a/libsystem_c.dylib.dSYM")
#target.SetSectionLoadAddress(module.FindSection("__TEXT"), 0x7fff83f32000)
#                                for sec in target.module[options.shlibs].section_iter():
#                                        if sec.GetName() == ".text" or sec.GetName() == "__TEXT":
#                                                print sec
#                                                print sec.GetLoadAddress(target)
#                                exit(0)
                                #print "Breakpoint"

