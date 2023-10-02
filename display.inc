
macro __digit num
{
   if num < 10
    display '0'+num
   else
    display 'A'+num-10
   end if
}


macro _disp arg1, arg2
{
   if arg2 eq 
    display arg1
   else
    local ..tmp, ..val

    if arg1 relativeto 0
      ..tmp = arg1
    else
      ..tmp = rva arg1
    end if

    virtual at 0
     repeat 32
      if ..tmp > 0
       db ..tmp mod arg2
       ..tmp = ..tmp / arg2
      end if
     end repeat
     repeat $
      load ..tmp byte from $-%
      __digit ..tmp
     end repeat
     if $ = 0
      display '0'
     end if
    end virtual
   end if
}

macro disp [arg] { _disp arg }


macro DispSize Text, Sz {
  local size
  size = Sz;
  if defined options.ShowSizes & options.ShowSizes
    if ~(defined options.SkipZeroSizes & options.SkipZeroSizes & Sz=0)
      if Text eqtype "A"
        disp 3,"Sizeof [", Text, "] is: "
      else
        disp 3,"Sizeof [", `Text, "] is: "
      end if

      if Sz>10000
        size = size / 1024
        disp <size,10>, 'K',$0d,$0a
      else
        disp <size,10>, ' bytes.',$0d,$0a
      end if
    end if
  end if
}
