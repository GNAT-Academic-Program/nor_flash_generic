with Nor_Flash_Types;

package body Nor_Flash_Data is

   use type MT.UInt8;
   use type MT.UInt32;

   --  NOR flash data-plane command bytes
   CMD_WREN      : constant MT.UInt8 := 16#06#;  --  Write Enable
   CMD_PAGE_PROG : constant MT.UInt8 := 16#02#;  --  Page Program
   CMD_FAST_READ : constant MT.UInt8 := 16#0B#;  --  Fast Read (1 dummy cycle)

   --  Status register 1 bit masks
   WIP_BIT : constant MT.UInt8 := 16#01#;  --  Write In Progress

   WIP_Poll_Limit : constant Natural := 1_000_000;

   --  W25Q128 requires 1 dummy byte at standard SPI frequencies.
   --  See file-level TODO for variable dummy cycle support.
   FAST_READ_DUMMY_CYCLES : constant Natural := 1;

   --  Page program requires no dummy cycles.
   PAGE_PROG_DUMMY_CYCLES : constant Natural := 0;

   ------------------------------------------------------------
   --  Private helpers
   ------------------------------------------------------------

   procedure Write_Enable (Dev : in out Device) is
   begin
      Bus_Command (Dev, CMD_WREN);
   end Write_Enable;

   procedure Poll_WIP (Dev : in out Device) is
      SR         : MT.UInt8;
      Poll_Count : Natural := 0;
   begin
      loop
         Bus_Read_Status (Dev, SR);
         exit when (SR and WIP_BIT) = 0;
         delay 0.01;
      end loop;
   end Poll_WIP;

   ----------------
   -- Write_Page --
   ----------------
   --  W25Q128 page size is 256 bytes.  Writing across a page boundary
   --  causes the device to wrap silently within the page, corrupting data.
   --  We detect this and raise Nor_Error rather than wrap.

   procedure Write_Page
     (Dev  : in out Device;
      Addr :        Nor_Flash_Types.Nor_Address;
      Buf  :        Storage_Array)
   is
      Page_Size  : constant Nor_Flash_Types.Nor_Address := 256;
      Page_Start : constant Nor_Flash_Types.Nor_Address :=
        (Addr / Page_Size) * Page_Size;
      Page_End   : constant Nor_Flash_Types.Nor_Address :=
        Page_Start + Page_Size - 1;
      Write_End  : constant Nor_Flash_Types.Nor_Address :=
        Addr + Nor_Flash_Types.Nor_Address (Buf'Length) - 1;
   begin
      if Write_End > Page_End then
         raise Nor_Flash_Types.Nor_Error;
      end if;

      Write_Enable (Dev);
      Bus_Write (Dev, CMD_PAGE_PROG, Addr, PAGE_PROG_DUMMY_CYCLES, Buf);
      Poll_WIP (Dev);
   end Write_Page;

   ----------
   -- Read --
   ----------

   procedure Read
     (Dev  : in out Device;
      Addr :        Nor_Flash_Types.Nor_Address;
      Buf  :    out Storage_Array)
   is
   begin
      Bus_Read (Dev, CMD_FAST_READ, Addr, FAST_READ_DUMMY_CYCLES, Buf);
   end Read;

end Nor_Flash_Data;