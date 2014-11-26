from optparse import OptionParser
import lldb
import lldbutil
import sys
from lxml import etree as ET
import os

class Action(object):
    """Class that encapsulates actions to take when a thread stops for a reason."""
    def __init__(self, callback = None, callback_owner = None):
        self.callback = callback
        self.callback_owner = callback_owner
    def ThreadStopped (self, thread):
        assert False, "performance.Action.ThreadStopped(self, thread) must be overridden in a subclass"

class BreakpointAction(Action):
    def __init__(self, callback = None, callback_owner = None, name = None, module = None, file = None, line = None, breakpoint = None):
        Action.__init__(self, callback, callback_owner)
        self.modules = lldb.SBFileSpecList()
        self.files = lldb.SBFileSpecList()
        self.breakpoints = list()
        # "module" can be a list or a string
        if breakpoint:
            self.breakpoints.append(breakpoint)
        else:
            if module:
                if isinstance(module, types.ListType):
                    for module_path in module:
                        self.modules.Append(lldb.SBFileSpec(module_path, False))
                elif isinstance(module, types.StringTypes):
                    self.modules.Append(lldb.SBFileSpec(module, False))
            if name:
                # "file" can be a list or a string
                if file:
                    if isinstance(file, types.ListType):
                        self.files = lldb.SBFileSpecList()
                        for f in file:
                            self.files.Append(lldb.SBFileSpec(f, False))
                    elif isinstance(file, types.StringTypes):
                        self.files.Append(lldb.SBFileSpec(file, False))
                self.breakpoints.append (self.target.BreakpointCreateByName(name, self.modules, self.files))
            elif file and line:
                self.breakpoints.append (self.target.BreakpointCreateByLocation(file, line))

    def ThreadStopped (self, thread):
        if thread.GetStopReason() == lldb.eStopReasonBreakpoint:
#            for bp in self.breakpoints:
#                if bp.GetID() == thread.GetStopReasonDataAtIndex(0):
            if self.callback:
                if self.callback_owner:
                    self.callback (self.callback_owner, thread)
                else:
                    self.callback (thread)
                return True
        return False

class TestCase:
    """Class that aids in running performance tests."""
    def __init__(self):
        self.verbose = False 
        self.debugger = lldb.SBDebugger.Create()
        self.target = None
        self.process = None
        self.thread = None
        self.launch_info = None
        self.done = False
        self.listener = self.debugger.GetListener()
        self.user_actions = list()
        self.builtin_actions = list()
        self.bp_id_to_dict = dict()

    def Setup(self, args, env_vars=None):
        self.launch_info = lldb.SBLaunchInfo(args)
        if env_vars:
            self.launch_info.SetEnvironmentEntries(env_vars, True)
    
    def Launch(self):
        if self.target:
            error = lldb.SBError()
            self.process = self.target.Launch (self.launch_info, error)
            if not error.Success():
                print "error: %s" % error.GetCString()
            if self.process:
                self.process.GetBroadcaster().AddListener(self.listener, lldb.SBProcess.eBroadcastBitStateChanged | lldb.SBProcess.eBroadcastBitInterrupt)
                return True
        return False

    def WaitForNextProcessEvent (self):
        event = None
        if self.process:
            while event is None:
                process_event = lldb.SBEvent()
                if self.listener.WaitForEvent (lldb.UINT32_MAX, process_event):
                    state = lldb.SBProcess.GetStateFromEvent (process_event)
                    if self.verbose:
                        print "event = %s" % (lldb.SBDebugger.StateAsCString(state))
                    if lldb.SBProcess.GetRestartedFromEvent(process_event):
                        continue
                    if state == lldb.eStateInvalid or state == lldb.eStateDetached or state == lldb.eStateCrashed or  state == lldb.eStateUnloaded or state == lldb.eStateExited:
                        event = process_event
                        self.done = True
                    elif state == lldb.eStateConnected or state == lldb.eStateAttaching or state == lldb.eStateLaunching or state == lldb.eStateRunning or state == lldb.eStateStepping or state == lldb.eStateSuspended:
                        continue
                    elif state == lldb.eStateStopped:
                        event = process_event
                        call_test_step = True
                        fatal = False
                        selected_thread = False
                        for thread in self.process:
                            frame = thread.GetFrameAtIndex(0)
                            select_thread = False

                            stop_reason = thread.GetStopReason()
                            if self.verbose:
                                print "tid = %#x pc = %#x " % (thread.GetThreadID(),frame.GetPC()),
                            if stop_reason == lldb.eStopReasonNone:
                                if self.verbose:
                                    print "none"
                                elif stop_reason == lldb.eStopReasonTrace:
                                    select_thread = True
                                if self.verbose:
                                    print "trace"
                                elif stop_reason == lldb.eStopReasonPlanComplete:
                                    select_thread = True
                                if self.verbose:
                                    print "plan complete"
                                elif stop_reason == lldb.eStopReasonThreadExiting:
                                    if self.verbose:
                                        print "thread exiting"
                                    elif stop_reason == lldb.eStopReasonExec:
                                        if self.verbose:
                                            print "exec"
                                        elif stop_reason == lldb.eStopReasonInvalid:
                                            if self.verbose:
                                                print "invalid"
                                            elif stop_reason == lldb.eStopReasonException:
                                                select_thread = True
                                if self.verbose:
                                    print "exception"
                                fatal = True
                            elif stop_reason == lldb.eStopReasonBreakpoint:
                                select_thread = True
                                bp_id = thread.GetStopReasonDataAtIndex(0)
                                bp_loc_id = thread.GetStopReasonDataAtIndex(1)
                                if self.verbose:
                                    print "breakpoint id = %d.%d" % (bp_id, bp_loc_id)
                                elif stop_reason == lldb.eStopReasonWatchpoint:
                                    select_thread = True
                                if self.verbose:
                                    print "watchpoint id = %d" % (thread.GetStopReasonDataAtIndex(0))
                                elif stop_reason == lldb.eStopReasonSignal:
                                    select_thread = True
                                if self.verbose:
                                    print "signal %d" % (thread.GetStopReasonDataAtIndex(0))

                            if select_thread and not selected_thread:
                                self.thread = thread
                                selected_thread = self.process.SetSelectedThread(thread)

                            for action in self.user_actions:
                                action.ThreadStopped (thread)

                        if fatal:
                            sys.exit(1)
        return event

class TesterTestCase(TestCase):
    def __init__(self, xmlfile):
        TestCase.__init__(self)
        self.verbose = False 
        self.num_steps = 5
        self.xml_file = xmlfile
        self.shared_lib = None

    def BreakpointHit(self, thread):
        bp_id = thread.GetStopReasonDataAtIndex(0)
        loc_id = thread.GetStopReasonDataAtIndex(1)
#        print "Breakpoint %i.%i hit: %s" % (bp_id, loc_id, thread.process.target.FindBreakpointByID(bp_id))
        thread.Resume()
        thread.process.Continue()

    def Run(self, exe, args, pipeout, shared_lib, env_vars=None):
        self.Setup(args, env_vars)
        self.target = self.debugger.CreateTargetWithFileAndArch(exe, lldb.LLDB_ARCH_DEFAULT)
        self.shared_lib = shared_lib
        if self.target:
            self.user_actions.append(BreakpointAction(breakpoint=shared_lib, callback=TesterTestCase.BreakpointHit, callback_owner=self))
            lib_breakpoints = self.target.BreakpointCreateByRegex(".", shared_lib)

            if self.Launch():
                os.write(pipeout, "%s\n" % self.process.GetProcessID())
                while not self.done:
                    self.WaitForNextProcessEvent()
            else:
                 print "error: failed to launch process"
        else:
            print "error: failed to create target with '%s'" % (args)
    
    def BreakStats(self):
        root = ET.Element("fuzz.io")
        secStartAddr = None
        secEndAddr = None

        # Do not record hits at start and end addresses
        for sec in self.target.module[self.shared_lib].section_iter():
            if sec.GetName() == ".text" or sec.GetName() == "__TEXT":
#            [0x0000000000033240-0x00000000000c0c08) libbfd-2.22-system.so..text
                secInfo = str(sec).split("-")
                secEndAddr = secInfo[1].split(")")[0]
                secStartAddr = secInfo[0].split("[")[1]

        for breakpoint in self.target.breakpoint_iter():
            for breakpointLocation in breakpoint:
                # Hack since I can't find a GetHitCount() for a SBBreakpointLocation
                breakPointLocationInfo = str(breakpointLocation).split(",")
                blFuncName = breakPointLocationInfo[0].split("=")[1] 
                blLoadAddress = hex(breakpointLocation.GetAddress().GetFileAddress())
                blHitCount = breakPointLocationInfo[3].split("=")[1]
                blHitCount = int(blHitCount)
                if(blHitCount > 0) and (int(blLoadAddress[:-1], 16) != int(secEndAddr, 16)) and (int(blLoadAddress[:-1], 16) != int(secStartAddr, 16)):
                    hit = ET.SubElement(root, 'hit')
                    funcname = ET.SubElement(hit, "funcname")
                    funcname.text = blFuncName
                    offset = ET.SubElement(hit, "offset")
                    offset.text = blLoadAddress
                    count = ET.SubElement(hit, "count")
                    count.text = str(blHitCount) 

        traceFile = open(self.xml_file, "w")
        ET.ElementTree(root).write(traceFile, pretty_print=True, xml_declaration=True) 
        traceFile.close()

if __name__ == '__main__':
    description='''Records hit traces for all functions of a specific shared library'''
    epilog='''Examples:% ./lldb-test.py -x lldbtrace.xml -s sharedlibrary -- /Applications/Preview.app/Contents/MacOS/Preview'''
    parser = OptionParser(description=description, prog='lldb-func-tracer.py',usage='usage: lldb-func-tracer.py [options] -- program [arg1 arg2]', epilog=epilog)
#    OptionParser.format_epilog = lambda self, formatter: self.epilog
    parser.add_option('-e', '--environment', action='append', type='string', metavar='ENV', dest='env_vars', help='Environment variables to set in the inferior process when launching a process.')
    parser.add_option('-p', '--pipe', type='string', metavar='PIPE', dest='pipe', help='Specify the pipe for interprocess communication with the mamba fuzzing framework.')
    parser.add_option('-s', '--shlib', type='string', dest='shlibs', metavar='SHLIB', help='Specify the shared library to trace functions')
    parser.add_option('-t', '--event-timeout', type='int', dest='event_timeout', metavar='SEC', help='Specify the timeout in seconds to wait for process state change events.', default=lldb.UINT32_MAX)
    parser.add_option('-x', '--xmlfile', type='string', dest='xmlfile', metavar='XML', help='Specify an XML file to write lldb traces')
    try:
        (options, args) = parser.parse_args()
    except Exception, e:
        print e
        sys.exit(1)

    # Initialize the debugger
    lldb.SBDebugger.Initialize()

    # Set the executable
    exe = args.pop(0)

    # Set the testcase
    test = TesterTestCase(options.xmlfile)

    pipeout = os.open(options.pipe, os.O_WRONLY)
    test.Run(exe, args, pipeout, options.shlibs, options.env_vars)
    
    test.BreakStats()

    # Destroy the debugger instance
    lldb.SBDebugger.Terminate()
