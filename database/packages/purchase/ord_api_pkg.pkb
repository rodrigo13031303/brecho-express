CREATE OR REPLACE PACKAGE BODY ord_api_pkg AS
  FUNCTION js(p ord_service_pkg.t_record) RETURN JSON_OBJECT_T IS j JSON_OBJECT_T:=JSON_OBJECT_T();
    a JSON_ARRAY_T:=JSON_ARRAY_T();x JSON_OBJECT_T;i PLS_INTEGER:=p.items.FIRST;
  BEGIN core_json_pkg.put_string(j,'orderPublicId',TRIM(p.order_public_id));
    core_json_pkg.put_string(j,'orderNumber',p.order_number);core_json_pkg.put_string(j,'status',p.status);
    core_json_pkg.put_number(j,'subtotalAmount',p.subtotal_amount);core_json_pkg.put_number(j,'discountAmount',p.discount_amount);
    core_json_pkg.put_number(j,'shippingAmount',p.shipping_amount);core_json_pkg.put_number(j,'totalAmount',p.total_amount);
    core_json_pkg.put_string(j,'paidAt',core_json_pkg.format_timestamp(p.paid_at));
    WHILE i IS NOT NULL LOOP x:=JSON_OBJECT_T();core_json_pkg.put_string(x,'itemPublicId',TRIM(p.items(i).item_public_id));
      core_json_pkg.put_string(x,'productPublicId',TRIM(p.items(i).product_public_id));
      core_json_pkg.put_string(x,'storePublicId',TRIM(p.items(i).store_public_id));
      core_json_pkg.put_number(x,'quantity',p.items(i).quantity);core_json_pkg.put_number(x,'totalPrice',p.items(i).total_price);
      core_json_pkg.append_element(a,x);i:=p.items.NEXT(i);END LOOP;j.put('items',a);RETURN j;END;
  PROCEDURE get_order(p_public VARCHAR2,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS r ord_service_pkg.t_record;
  BEGIN r:=ord_service_pkg.get_order(p_public,p_actor);o_body:=core_response_pkg.build_success(js(r));o_status:=200;
  EXCEPTION WHEN ord_service_pkg.e_not_found THEN o_status:=404;o_body:=NULL;
    WHEN ord_service_pkg.e_forbidden THEN o_status:=403;o_body:=NULL;WHEN OTHERS THEN o_status:=500;o_body:=NULL;END;
END ord_api_pkg;
/
