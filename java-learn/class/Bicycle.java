public class Bicycle
{
	public int gear;
	public int speed;
	public int cadence;
	public Bicycle(int startCadence, int startSpeed, int startGear){
		gear = startGear;
		cadence = startCadence;
		speed = startSpeed;
	}
	public void setCadence( int newValue)
	{
		gear = newValue;
	}
	public void setSpeed( int newValue)
	{
		speed = newValue;
	}
	public void setGear(int newValue)
	{
		gear = newValue;
	}
	public void print()
	{
		System.out.println("Cadence:"+cadence+";Speed:"+speed+";Gear:"+gear);	
	}
	public static void main(String[] args)
	{
		Bicycle bike = new Bicycle(1,2,3);
		bike.print();
		bike.setGear(100);
		bike.speed = 10;
		bike.print();
	}
}
