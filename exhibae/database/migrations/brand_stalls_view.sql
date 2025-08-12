-- Create a view to show all stalls associated with a brand through applications
CREATE OR REPLACE VIEW public.brand_stalls_view AS
SELECT 
  sa.id AS application_id,
  sa.brand_id,
  sa.exhibition_id,
  sa.stall_id,
  sa.stall_instance_id,
  sa.status AS application_status,
  sa.message AS application_message,
  sa.booking_confirmed,
  sa.created_at AS application_created_at,
  sa.updated_at AS application_updated_at,
  s.name AS stall_name,
  s.description AS stall_description,
  s.length AS stall_length,
  s.width AS stall_width,
  s.height AS stall_height,
  s.price AS stall_price,
  s.measurement_unit_id AS stall_unit_id,
  s.created_at AS stall_created_at,
  s.updated_at AS stall_updated_at,
  si.position_x,
  si.position_y,
  si.rotation_angle,
  si.status AS instance_status,
  si.instance_number,
  si.price AS instance_price,
  si.original_price AS instance_original_price,
  si.created_at AS instance_created_at,
  si.updated_at AS instance_updated_at,
  e.title AS exhibition_title,
  e.start_date AS exhibition_start_date,
  e.end_date AS exhibition_end_date,
  e.address AS exhibition_address,
  e.city AS exhibition_city,
  e.state AS exhibition_state,
  e.country AS exhibition_country,
  e.status AS exhibition_status,
  e.created_at AS exhibition_created_at,
  e.updated_at AS exhibition_updated_at,
  mu.name AS unit_name,
  mu.symbol AS unit_symbol,
  mu.type AS unit_type,
  (
    SELECT json_agg(json_build_object(
      'id', a.id,
      'name', a.name,
      'description', a.description,
      'icon', a.icon
    ))
    FROM stall_amenities sa2
    JOIN amenities a ON a.id = sa2.amenity_id
    WHERE sa2.stall_id = s.id
  ) AS amenities
FROM 
  stall_applications sa
  JOIN stalls s ON s.id = sa.stall_id
  LEFT JOIN stall_instances si ON si.id = sa.stall_instance_id
  JOIN exhibitions e ON e.id = sa.exhibition_id
  LEFT JOIN measurement_units mu ON mu.id = s.measurement_unit_id
WHERE 
  sa.brand_id IS NOT NULL;

-- Add comment to the view
COMMENT ON VIEW public.brand_stalls_view IS 'A view that shows all stalls associated with a brand through their applications, including exhibition, instance, and amenity details';

-- Grant permissions
GRANT SELECT ON public.brand_stalls_view TO authenticated;
GRANT SELECT ON public.brand_stalls_view TO service_role;
