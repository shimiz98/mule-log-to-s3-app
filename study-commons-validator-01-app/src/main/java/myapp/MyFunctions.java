package myapp;

import java.io.IOException;
import java.text.MessageFormat;
import java.util.Iterator;
import java.util.Locale;
import java.util.ResourceBundle;

import org.apache.commons.validator.Field;
import org.apache.commons.validator.Form;
import org.apache.commons.validator.Validator;
import org.apache.commons.validator.ValidatorAction;
import org.apache.commons.validator.ValidatorException;
import org.apache.commons.validator.ValidatorResources;
import org.apache.commons.validator.ValidatorResult;
import org.apache.commons.validator.ValidatorResults;
import org.xml.sax.SAXException;

public class MyFunctions {
	static ValidatorResources validatorResources;
	private static ResourceBundle apps = ResourceBundle
			.getBundle("myapp.validateMessageResources");
	static {
		try {
			validatorResources = new ValidatorResources(
					MyFunctions.class.getResourceAsStream("validator-definition.xml"));
		} catch (IOException | SAXException e) {
			throw new RuntimeException(e);
		}
	}

	public static boolean validate(Object bean, String formName) throws IOException, SAXException, ValidatorException {
		// Create a validator with the ValidateBean actions for the bean we're interested in.
		Validator validator = new Validator(validatorResources, formName);

		// Tell the validator which bean to validate against.
		validator.setParameter(Validator.BEAN_PARAM, bean);	

        // Now only report failed fields
        validator.setOnlyReturnErrors(true);

        // Run the validation actions against the bean.
		ValidatorResults validatorResults = validator.validate();

		// Print Results
		return printResults(bean, validatorResults, validatorResources, formName);
	}

	/**
	 * Dumps out the Bean in question and the results of validating it.
	 * https://github.com/apache/commons-validator/blob/master/src/example/org/apache/commons/validator/example/ValidateExample.java
	 */
	public static boolean printResults(Object bean, ValidatorResults results, ValidatorResources resources, String formName) {

		boolean success = true;

		// Start by getting the form for the current locale and Bean.
		Form form = resources.getForm(Locale.getDefault(), formName);

		System.out.println("\n\nValidating:");
		System.out.println(bean);

		// Iterate over each of the properties of the Bean which had messages.
		Iterator<String> propertyNames = results.getPropertyNames().iterator();
		while (propertyNames.hasNext()) {
			String propertyName = propertyNames.next();

			// Get the Field associated with that property in the Form
			Field field = form.getField(propertyName);

			// Look up the formatted name of the field from the Field arg0
			String prettyFieldName = apps.getString(field.getArg(0).getKey());

			// Get the result of validating the property.
			ValidatorResult result = results.getValidatorResult(propertyName);

			// Get all the actions run against the property, and iterate over their names.
			Iterator<String> keys = result.getActions();
			while (keys.hasNext()) {
				String actName = keys.next();

				// Get the Action for that name.
				ValidatorAction action = resources.getValidatorAction(actName);

				// If the result is valid, print PASSED, otherwise print FAILED
				System.out.println(
						propertyName + "[" + actName + "] (" + (result.isValid(actName) ? "PASSED" : "FAILED") + ")");

				// If the result failed, format the Action's message against the formatted field
				// name
				if (!result.isValid(actName)) {
					success = false;
					String message = apps.getString(action.getMsg());
					Object[] args = { prettyFieldName };
					System.out.println("     Error message will be: " + MessageFormat.format(message, args));
				}
			}
		}
		if (success) {
			System.out.println("FORM VALIDATION PASSED");
		} else {
			System.out.println("FORM VALIDATION FAILED");
		}
		return success;
	}
}
