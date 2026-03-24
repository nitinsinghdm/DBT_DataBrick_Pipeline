{%- set apples = ['Fuji', 'McIntosh', 'Red Delicious', 'Gala'] %}

{%- for i in apples %}

    {% if i != 'McIntosh' %}
         {{- i }}
    {%- else -%}
         I hate {{ i }}
    {%- endif %}

{%- endfor %}