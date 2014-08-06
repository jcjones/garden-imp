# The Garden Imp

Using an [Electric Imp](http://electricimp.com/) and two [Vegetronix VH400 soil moisture sensors](http://vegetronix.com/Products/VH400/), I am now able to monitor the [water content](http://en.wikipedia.org/wiki/Water_content) of two locations in my garden.

Right now this system uses Electric Imp's infrastructure for data transmission; all readings are sent via HTTPS to their servers and then queried from there. Since this all fits into the definition of an [IoT Node of No Security Consequence](https://tacticalsecret.com/pan-parts-iot), I'm alright with the information belonging to them for the time being, and re-evaluating as I add more functionality. The next step is to utilize this as a [SAIFE endpoint for management](http://saifeinc.com/saife/).

The source code for the Agent and the Device, the two pieces of the [Electric Imp infrastructure](http://electricimp.com/docs/gettingstarted/3-agents/), are included below.

### Obligatory Screenshot
![Garden Imp Screenshot](GardenImp GUI-full.jpg)

## Source Code
The source code can be found at my GitHub page: https://github.com/jcjones/garden-imp

There are two files, one for the [Agent](agent.nut) and one for the [Device](device.nut).

## License
This code is released under the MIT License.
