
Function TZOFFSET() As Integer
	Dim oScriptProvider, oScript
	oScriptProvider = ThisComponent.getScriptProvider()
	oScript = oScriptProvider.getScript("vnd.sun.star.script:Module.py$getgmtoff?language=Python&location=document")
	'                                                                                                     user  pentru globale, document pentru moon.ods, ...
	'                                                        HelloWorld.py$HelloWorldPython?language=Python&location=share
	TZOFFSET=oScript.invoke(array(), array(), array())
	REM                          (A1,...)
End Function

'add buttons for macros from Tools > Customize

Global oSelListener As Object
Global bTraceDependentsOn As Boolean
Global bTracePrecedentsOn As Boolean

Sub EnableBothTraces()
	bTraceDependentsOn = True
	bTracePrecedentsOn = True
	EnsureListenerState()
	'LogLine("Both enabled: dep=" & bTraceDependentsOn & " prec=" & bTracePrecedentsOn)
End Sub
Sub DisableTraces()
	bTraceDependentsOn = False
	bTracePrecedentsOn = False
	EnsureListenerState()
End Sub
Sub ToggleTraceDependents()
	bTraceDependentsOn = Not bTraceDependentsOn
	EnsureListenerState()
	'LogLine("Dependents: " & bTraceDependentsOn)
End Sub
Sub ToggleTracePrecedents()
	bTracePrecedentsOn = Not bTracePrecedentsOn
	EnsureListenerState()
	'LogLine("Precedents: " & bTracePrecedentsOn)
End Sub

Sub EnsureListenerState()
	On Error Resume Next
	Dim oController As Object
	oController = ThisComponent.getCurrentController()

	If Not IsNull(oSelListener) Then
		oController.removeSelectionChangeListener(oSelListener)
	End If

	If (bTraceDependentsOn Or bTracePrecedentsOn) Then
		oSelListener = createUnoListener("SelListener_", "com.sun.star.view.XSelectionChangeListener")
		oController.addSelectionChangeListener(oSelListener)
		SelListener_selectionChanged(Nothing)   ' fire immediately on the current cell
	Else
		ClearArrows()
	End If
End Sub

Sub SelListener_selectionChanged(oEvent As Object)
	On Error Resume Next
	Dim oFrame As Object
	Dim oDispatcher As Object
	Dim oSheet As Object
	Dim oDrawPage As Object
	Dim nCountBefore As Integer
	Dim nCountAfterPrec As Integer
	Dim nCountAfterDep As Integer
	Dim PRECEDENTS_COLOR As Long
	Dim DEPENDENTS_COLOR As Long

	Dim bWasModified As Boolean
	bWasModified = ThisComponent.isModified()

	' Colors used for the two arrow kinds. Change these if you want different shades.
	PRECEDENTS_COLOR = RGB(0, 0, 255)   ' blue
	DEPENDENTS_COLOR = RGB(255, 0, 0)   ' red

	oFrame = ThisComponent.getCurrentController().Frame
	oDispatcher = createUnoService("com.sun.star.frame.DispatchHelper")

	oDispatcher.executeDispatch(oFrame, ".uno:ClearArrows", "", 0, Array())

	oSheet = ThisComponent.getCurrentController().getActiveSheet()
	oDrawPage = oSheet.getDrawPage()
	nCountBefore = oDrawPage.Count

	' Precedents first, so we know exactly which new shapes belong to it
	If bTracePrecedentsOn Then
		oDispatcher.executeDispatch(oFrame, ".uno:ShowPrecedents", "", 0, Array())
		nCountAfterPrec = oDrawPage.Count
		ColorArrowRange(oDrawPage, nCountBefore, nCountAfterPrec - 1, PRECEDENTS_COLOR)
	Else
		nCountAfterPrec = nCountBefore
	End If

	If bTraceDependentsOn Then
		oDispatcher.executeDispatch(oFrame, ".uno:ShowDependents", "", 0, Array())
		nCountAfterDep = oDrawPage.Count
		ColorArrowRange(oDrawPage, nCountAfterPrec, nCountAfterDep - 1, DEPENDENTS_COLOR)
	End If

	ThisComponent.setModified(bWasModified)
End Sub

' Sets LineColor on every shape in oDrawPage whose index is within [iStart, iEnd].
' Used right after a ShowPrecedents/ShowDependents dispatch to recolor only the
' arrows that dispatch just added (shapes are appended, so the range is the
' slice of new shapes since the previous draw-page count).
Sub ColorArrowRange(oDrawPage As Object, iStart As Integer, iEnd As Integer, nColor As Long)
	On Error Resume Next
	Dim i As Integer
	Dim oShape As Object
	For i = iStart To iEnd
		If i >= 0 And i < oDrawPage.Count Then
			oShape = oDrawPage.getByIndex(i)
			oShape.LineColor = nColor
		End If
	Next i
End Sub

'If disposing is missing, it doesn't always throw immediately, but behavior becomes unreliable — some LibreOffice versions raise an error at registration time, others silently fail to call it later and can leave you with warnings in a log, or occasionally crash-adjacent behavior during document close. It's cheap enough to keep as an empty stub that there's no real reason to risk it.
Sub SelListener_disposing(oEvent As Object)
End Sub

Sub ClearArrows()
	On Error Resume Next
	Dim oFrame As Object
	Dim oDispatcher As Object

	Dim bWasModified As Boolean
	bWasModified = ThisComponent.isModified()

	oFrame = ThisComponent.getCurrentController().Frame
	oDispatcher = createUnoService("com.sun.star.frame.DispatchHelper")
	oDispatcher.executeDispatch(oFrame, ".uno:ClearArrows", "", 0, Array())

	ThisComponent.setModified(bWasModified)
End Sub

'Const LOG_PATH As String = "/tmp/trace_toggle.log"
'Sub LogLine(sMsg As String)
'	On Error Resume Next
'	Dim iFile As Integer
'	iFile = FreeFile
'	Open LOG_PATH For Append As #iFile
'	Print #iFile, Format(Now, "YYYY-MM-DD HH:MM:SS") & "  " & sMsg
'	Close #iFile
'End Sub

Sub UnsetModified()
	ThisComponent.setModified(False)
End Sub
