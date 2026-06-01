with Nor_Flash_Control;
with Nor_Flash_Data;

package body Nor_Flash_Interface is

   ------------------------------------------------------------
   --  Internal instantiations
   ------------------------------------------------------------

   package Control is new Nor_Flash_Control
     (Device              => Device,
      Bus_Command         => Bus_Command,
      Bus_Command_Address => Bus_Command_Address,
      Bus_Read_Status     => Bus_Read_Status,
      Bus_Command_Read    => Bus_Command_Read,
      Driver_Config       => Driver_Config,
      Driver_Read_SR2     => Driver_Read_SR2,
      Driver_Write_Status => Driver_Write_Status);

   package Data is new Nor_Flash_Data
     (Device          => Device,
      Bus_Command     => Bus_Command,
      Bus_Read_Status => Bus_Read_Status,
      Bus_Write       => Bus_Write,
      Bus_Read        => Bus_Read);

   ------------------------------------------------------------
   --  Control plane
   ------------------------------------------------------------

   procedure Open (Dev : in out Device) is
   begin
      Control.Wake (Dev);
      Control.Init (Dev);
   end Open;

   procedure Close (Dev : in out Device) is
   begin
      Control.Sleep (Dev);
   end Close;

   procedure Reset (Dev : in out Device) is
   begin
      Control.Reset (Dev);
   end Reset;

   procedure Erase_Sector
     (Dev : in out Device;
      Idx : Nor_Flash_Types.Sector_Index)
   is
   begin
      Control.Erase_Sector (Dev, Idx);
   end Erase_Sector;

   procedure Erase_Block
     (Dev : in out Device;
      Idx : Nor_Flash_Types.Block_Index)
   is
   begin
      Control.Erase_Block (Dev, Idx);
   end Erase_Block;

   procedure Erase_Chip (Dev : in out Device) is
   begin
      Control.Erase_Chip (Dev);
   end Erase_Chip;

   ------------------------------------------------------------
   --  Data plane
   ------------------------------------------------------------

   procedure Write_Page
     (Dev  : in out Device;
      Addr :        Nor_Flash_Types.Nor_Address;
      Buf  :        Storage_Array)
   is
   begin
      Data.Write_Page (Dev, Addr, Buf);
   end Write_Page;

   procedure Read
     (Dev  : in out Device;
      Addr :        Nor_Flash_Types.Nor_Address;
      Buf  :    out Storage_Array)
   is
   begin
      Data.Read (Dev, Addr, Buf);
   end Read;

end Nor_Flash_Interface;
