----------------------------------------------------------------------------
-- Lua code generated with wxFormBuilder (version Jun  5 2014)
-- http://www.wxformbuilder.org/
----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

UI = {}


-- create MyFrame1
UI.MyFrame1 = wx.wxFrame (wx.NULL, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxSize( 1107,278 ), wx.wxDEFAULT_FRAME_STYLE+wx.wxTAB_TRAVERSAL )
	UI.MyFrame1:SetSizeHints( wx.wxDefaultSize, wx.wxDefaultSize )
	
	UI.gbSizer1 = wx.wxGridBagSizer( 0, 0 )
	UI.gbSizer1:SetFlexibleDirection( wx.wxBOTH )
	UI.gbSizer1:SetNonFlexibleGrowMode( wx.wxFLEX_GROWMODE_SPECIFIED )
	
	UI.m_notebook1 = wx.wxNotebook( UI.MyFrame1, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize( 1920,1080 ), 0 )
	UI.m_scrolledWindow1 = wx.wxScrolledWindow( UI.m_notebook1, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize( -1,-1 ), wx.wxHSCROLL + wx.wxVSCROLL )
	UI.m_scrolledWindow1:SetScrollRate( 5, 5 )
	UI.gbSizer2 = wx.wxGridBagSizer( 0, 0 )
	UI.gbSizer2:SetFlexibleDirection( wx.wxBOTH )
	UI.gbSizer2:SetNonFlexibleGrowMode( wx.wxFLEX_GROWMODE_SPECIFIED )
	
	UI.m_grid1 = wx.wxGrid( UI.m_scrolledWindow1, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxHSCROLL + wx.wxVSCROLL )
	
	-- Grid
	UI.m_grid1:CreateGrid( 8, 16 )
	UI.m_grid1:EnableEditing( True )
	UI.m_grid1:EnableGridLines( True )
	UI.m_grid1:SetGridLineColour( wx.wxSystemSettings.GetColour( wx.wxSYS_COLOUR_ACTIVECAPTION ) )
	UI.m_grid1:EnableDragGridSize( True )
	UI.m_grid1:SetMargins( 0, 0 )
	
	-- Columns
	UI.m_grid1:AutoSizeColumns()
	UI.m_grid1:EnableDragColSize( True )
	UI.m_grid1:SetColLabelSize( 30 )
	UI.m_grid1:SetColLabelValue( 0, "名字" )
	UI.m_grid1:SetColLabelValue( 1, "等級" )
	UI.m_grid1:SetColLabelValue( 2, "血量" )
	UI.m_grid1:SetColLabelValue( 3, "滿血" )
	UI.m_grid1:SetColLabelValue( 4, "攻擊(物)(魔)" )
	UI.m_grid1:SetColLabelValue( 5, "物防" )
	UI.m_grid1:SetColLabelValue( 6, "魔防" )
	UI.m_grid1:SetColLabelValue( 7, "物易和減免" )
	UI.m_grid1:SetColLabelValue( 8, "魔易和減免" )
	UI.m_grid1:SetColLabelValue( 9, "行速" )
	UI.m_grid1:SetColLabelValue( 10, "暴擊" )
	UI.m_grid1:SetColLabelValue( 11, "暴傷" )
	UI.m_grid1:SetColLabelValue( 12, "閃避" )
	UI.m_grid1:SetColLabelValue( 13, "格擋" )
	UI.m_grid1:SetColLabelValue( 14, "命中" )
	UI.m_grid1:SetColLabelValue( 15, "急速" )
	UI.m_grid1:SetColLabelAlignment( wx.wxALIGN_CENTRE, wx.wxALIGN_CENTRE )
	
	-- Rows
	UI.m_grid1:AutoSizeRows()
	UI.m_grid1:EnableDragRowSize( True )
	UI.m_grid1:SetRowLabelSize( 80 )
	UI.m_grid1:SetRowLabelValue( 0, "hero1" )
	UI.m_grid1:SetRowLabelValue( 1, "hero2" )
	UI.m_grid1:SetRowLabelValue( 2, "hero3" )
	UI.m_grid1:SetRowLabelValue( 3, "hero4" )
	UI.m_grid1:SetRowLabelValue( 4, "enemy1" )
	UI.m_grid1:SetRowLabelValue( 5, "enemy2" )
	UI.m_grid1:SetRowLabelValue( 6, "enemy3" )
	UI.m_grid1:SetRowLabelValue( 7, "enemy4" )
	UI.m_grid1:SetRowLabelAlignment( wx.wxALIGN_CENTRE, wx.wxALIGN_CENTRE )
	
	-- Label Appearance
	
	-- Cell Defaults
	UI.m_grid1:SetDefaultCellAlignment( wx.wxALIGN_CENTRE, wx.wxALIGN_CENTRE )
	UI.gbSizer2:Add( UI.m_grid1, wx.wxGBPosition( 0, 0 ), wx.wxGBSpan( 1, 1 ), wx.wxALL, 5 )
	
	
	UI.m_scrolledWindow1:SetSizer( UI.gbSizer2 )
	UI.m_scrolledWindow1:Layout()
	UI.gbSizer2:Fit( UI.m_scrolledWindow1 )
	UI.m_notebook1:AddPage(UI.m_scrolledWindow1, "a page", False )
	
	UI.gbSizer1:Add( UI.m_notebook1, wx.wxGBPosition( 0, 1 ), wx.wxGBSpan( 1, 1 ), wx.wxALL + wx.wxEXPAND, 5 )
	
	
	UI.MyFrame1:SetSizer( UI.gbSizer1 )
	UI.MyFrame1:Layout()
	
	UI.MyFrame1:Centre( wx.wxHORIZONTAL )


--wx.wxGetApp():MainLoop()
