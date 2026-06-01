with Nor_Flash_Types;
with MT;
with System.Storage_Elements; use System.Storage_Elements;

--  TODO: dummy cycle count for fast read is currently hardcoded to 1.
--  JESD216 allows 0-8 dummy cycles depending on frequency and device.
--  Consider deriving Dummy_Cycles from the bus clock frequency at
--  instantiation time, or adding it as a generic formal constant.

generic
   type Device is limited private;

   --  Send a command byte with no address and no data payload.
   --  Handles CS assertion/release internally.
   --  Used here for WREN (0x06).
   with procedure Bus_Command
     (Dev : in out Device;
      Cmd :        MT.UInt8);

   --  Send READ_STATUS (0x05) and return SR1.
   --  Handles CS assertion/release internally.
   with procedure Bus_Read_Status
     (Dev    : in out Device;
      Status :    out MT.UInt8);

   --  Write a data payload to flash at Addr.
   --  Cmd selects the program command (e.g. PAGE_PROG 0x02).
   --  Dummy_Cycles dummy bytes are clocked before the data phase.
   --  Handles CS assertion/release internally.
   with procedure Bus_Write
     (Dev          : in out Device;
      Cmd          :        MT.UInt8;
      Addr         :        Nor_Flash_Types.Nor_Address;
      Dummy_Cycles :        Natural;
      Data         :        Storage_Array);

   --  Read a data payload from flash at Addr.
   --  Cmd selects the read command (e.g. FAST_READ 0x0B).
   --  Dummy_Cycles dummy bytes are clocked before the data phase.
   --  Handles CS assertion/release internally.
   with procedure Bus_Read
     (Dev          : in out Device;
      Cmd          :        MT.UInt8;
      Addr         :        Nor_Flash_Types.Nor_Address;
      Dummy_Cycles :        Natural;
      Data         :    out Storage_Array);

package Nor_Flash_Data is

   --  Write Buf to flash starting at Addr.
   --  Buf must not cross a page boundary; raises Nor_Error if violated.
   --  Target range must already be erased (all 0xFF).
   --  Write_Enable and WIP polling are handled internally.
   --  Raises Nor_Timeout if WIP does not clear in time.
   procedure Write_Page
     (Dev  : in out Device;
      Addr :        Nor_Flash_Types.Nor_Address;
      Buf  :        Storage_Array);

   --  Read Buf'Length bytes from flash starting at Addr.
   --  Uses fast-read command (0x0B) with one dummy cycle.
   --  Supports arbitrary length and address alignment.
   --  No erase precondition -- reads are unconditionally valid.
   procedure Read
     (Dev  : in out Device;
      Addr :        Nor_Flash_Types.Nor_Address;
      Buf  :    out Storage_Array);

end Nor_Flash_Data;